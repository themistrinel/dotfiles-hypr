# RTK - Rust Token Killer
# Aliases para comandos comuns passarem automaticamente pelo RTK.
# Não sobrescreve ls (eza) nem cat (bat) — esses já têm aliases melhores no config.fish.
# Para uso manual: rtk <cmd>  sempre funciona.

if command -q rtk
    alias git='rtk git'
    alias grep='rtk grep'
    alias find='rtk find'
    alias docker='rtk docker'
    alias cargo='rtk cargo'
    alias npm='rtk npm'
    alias yarn='rtk yarn'
    alias pnpm='rtk pnpm'
    alias bun='rtk bun'
end
