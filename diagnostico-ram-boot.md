# Diagnóstico — Consumo de ~3 GB de RAM logo após o boot

**Data/hora da coleta:** 2026-09-03, ~10:56–10:59 (uptime ~11 min, boot das 10:44:50)
**Método:** somente leitura (`free`, `/proc/meminfo`, `ps`, `systemd-cgtop`, `docker stats/inspect`, `journalctl`, `zramctl`, `systemd-analyze`). Nenhum arquivo/serviço/processo foi alterado.

---

## Ambiente

| Item | Valor |
|---|---|
| Sistema | Arch Linux (rolling), kernel `7.1.10-arch1-1` |
| Hardware | Intel X99, desktop; GPU AMD RX 570 (amdgpu, VRAM 4 GiB separada) |
| RAM total | 16 GiB (`MemTotal` 16 198 712 kB ≈ 15.4 GiB utilizáveis) |
| Ambiente gráfico | Hyprland (Wayland) via display manager `ly` (`ly@tty1.service`), sessão `c1` iniciada 10:45:07 |
| Shell / extras | fish, waybar, dunst, Xwayland, xdg-desktop-portal-hyprland/gtk, pipewire, wireplumber, gvfs |
| Swap | `/dev/zram0`, 4 GiB, algoritmo **zstd**, **0 bytes usados** (sem pressão de swap; `swappiness=60`) |

---

## Panorama de memória (11 min após o boot)

| Métrica | Valor |
|---|---|
| `free` — usado | 6.3–7.1 GiB (flutua com cache) |
| **Disponível (`MemAvailable`)** | **8.4–9.2 GiB** |
| `buff/cache` | 2.8–4.7 GiB (reclaimable) |
| AnonPages (RAM anon de processos) | 5.73 GiB |
| Shmem (compartilhada) | 252 MiB |
| Slab (kernel) | 277 MiB (SUnreclaim 175 MiB) |
| PageTables / KernelStack | 72 MiB / 26 MiB |
| GPU (contabilizado na RAM do sistema) | ~228 MiB (GPUActive + GPUReclaim) |
| THP (dentro do anon) | AnonHugePages 2.8 GiB (normal p/ Java/Chromium) |

**Conclusão preliminar importante:** o "usado" do `free` **não é cache**. O cache/buffers (~2.8–4.7 GiB) é contabilizado à parte e é reclaimable. Os ~5.7 GiB anon são memória real de processos.

---

## Os 10 maiores consumidores

| # | Processo/serviço | RSS/PSS |
|---|---|---|
| 1 | `abyssal-penpot-backend-1` — java (`penpot.jar`) | **1.9 GiB RSS** (~12% da RAM) |
| 2 | Helium browser (19 processos Chromium, `/opt/helium-browser-bin`) | PSS ~1.52 GiB (soma RSS 3.49 GiB) |
| 3 | `abyssal-penpot-frontend-1` | 678 MiB |
| 4 | `abyssal-penpot-exporter-1` | 133 MiB |
| 5 | `abyssal-penpot-postgres-1` (postgres:15) | 130 MiB |
| 6 | `abyssal-penpot-mcp-1` | 81 MiB |
| 7 | `abyssal-penpot-mailcatch-1` (mailcatcher) | 43 MiB |
| 8 | `abyssal-penpot-valkey-1` (valkey:8.1) | 27 MiB |
| 9 | Hyprland (179 MiB) + loupe (151 MiB) + docker/containerd daemons (~320 MiB) | ~0.65 GiB |
| 10 | Serviços de usuário (pipewire, wireplumber, portals, gvfs, keyring, backupd…) | ~1 GiB (cgroup) |

### Atribuição por cgroup (`systemd-cgtop`)

| Cgroup | Memória atual |
|---|---|
| `system.slice` — scopes docker (7 containers) | **3.24 GiB** |
| `docker.service` + `containerd.service` | ~320 MiB |
| `session-c1.scope` (Helium + Hyprland + sessão) | 4.8 GiB |
| `user@1000.service` | 1.0 GiB |

> Nota de medição: ~0.85 GiB do total "usado" no momento da coleta eram processos desta própria análise (`@codebufffreebu` + `bun`). Não fazem parte do cenário pós-boot do usuário.

---

## Linha do tempo do boot (10:44:50)

| Hora | Evento |
|---|---|
| 10:44:50 | kernel inicializa |
| **10:45:00.6** | containerd conecta aos 7 shims; **todos os containers Penpot sobem ~10 s após o boot** |
| 10:45:00 | processo java do backend (1.9 GiB) inicia |
| 10:45:07 | sessão gráfica / Hyprland inicia (`loginctl`) |

**Por que isso acontece sozinho:**
- `docker.service` está **habilitado** (`systemctl is-enabled docker` → enabled);
- os 7 serviços do compose em `/home/abyssal/docker-compose.yaml` têm **`restart: always`**;
- portanto a pilha sobe no boot **antes mesmo do login do usuário**.

---

## DIAGNÓSTICO

- **Causa principal:** pilha **Docker Penpot** (projeto `abyssal`, `docker-compose.yaml` em `/home/abyssal`, 7 serviços com `restart: always`) iniciada automaticamente no boot por `docker.service` habilitado. O backend Java sozinho consome ~1.9 GiB; a pilha inteira + daemons ≈ **3.3–3.6 GiB**.
- **Evidência:** cgroups docker = 3.24 GiB; containers iniciados em 10:45:00.6 (10 s após o kernel, antes do login às 10:45:07 — confirmado no journal); `restart: always` no compose; processo único `java -jar penpot.jar -m app.main` com 1.9 GiB RSS dentro de `abyssal-penpot-backend-1`.
- **Impacto:** ~3.2–3.6 GiB de RAM anon ocupados permanentemente + CPU (java ~9%, load ~2.6–3.3) + 7 processos de suporte sempre ativos. Disponibilidade ainda confortável (~9 GiB), mas o espaço disponível para IDE/VM/jogos fica reduzido.
- **Confiança da conclusão: alta.**

---

## OUTROS FATORES

- **Helium browser (secundário):** ~1.5 GiB PSS; se restaura muitas abas no login, contribui com ~1–2 GiB adicionais. É o navegador de uso do usuário — comportamento esperado, não vazamento.
- **Loupe (visualizador GNOME) rodando como serviço dbus:** ~151 MiB (ativação sob demanda; pequeno).
- **Boot lento (não é RAM):** `systemd-networkd-wait-online.service` leva **7.8 s** e o `docker.service` espera `network-online` — é o principal motivo do boot totalizar ~47 s.
- **Cache/buffers e THP:** normais e reclaimable; **ZRAM saudável (0 bytes usados)** — não há motivo para mexer em swappiness/zram.
- **Não há:** vazamento de memória, processos duplicados, serviços órfãos, containers/instâncias acidentais, nem pressão de swap.

---

## CORREÇÃO APLICADA (2026-09-03, autorizada pelo usuário)

1. **Se o Penpot é usado só de vez em quando (recomendado):**
   - Em `/home/abyssal/docker-compose.yaml`, trocar `restart: always` → `restart: "no"` nos serviços;
   - aplicar com `docker compose up -d` (recria os containers com a nova política);
   - subir manualmente com `docker compose up -d` quando for usar (ou criar alias `penpot-up`).
   - Economia esperada: **~3.2 GiB de RAM no boot**.
2. **Se o Penpot precisa ficar sempre disponível:** os ~3 GB são custo de operação (decisão legítima). Nada a corrigir na RAM; opcionalmente remover a espera de `systemd-networkd-wait-online` para acelerar o boot.
3. **Alternativa intermediária:** `systemctl disable docker` e subir containers sob demanda — afeta qualquer outro uso de Docker na máquina.
4. **Opcional:** definir `mem_limit` no compose (ex.: backend `2g`) como rede de segurança contra crescimento descontrolado (não reduz o uso normal).

**Status pós-correção:** opção 1 aplicada em 2026-09-03 — `/home/abyssal/docker-compose.yaml` editado (7× `restart: always` → `restart: "no"`), política aplicada nos containers com `docker update --restart=no` e pilha parada com `docker compose stop` (dados preservados nos volumes). `docker.service` permanece habilitado; o Penpot não sobe mais no boot e pode ser iniciado manualmente com `docker compose up -d` em `/home/abyssal`. Memória usada caiu de ~6.3–7.1 GiB para ~5.5 GiB logo após o stop.
