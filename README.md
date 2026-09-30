# kali-setup

Script de terminal para **atualizar o Kali Linux** e **instalar ferramentas** organizadas por categoria (reconhecimento, web, wireless, senhas, forense, etc.).

## Requisitos

- Kali Linux (ou outra distro Debian-based)
- Acesso `root` ou `sudo`
- Conexão com a internet

## Instalação

```bash
git clone https://github.com/thecreewkz/kali-setup.git
cd kali-setup
chmod +x kali-setup.sh
```

## Uso

```bash
# Atualiza o sistema + instala as categorias essenciais
sudo ./kali-setup.sh

# Atualiza o sistema + instala TODAS as categorias
sudo ./kali-setup.sh

# Somente atualizar o sistema
sudo ./kali-setup.sh --upgrade

# Instalar categorias específicas
sudo ./kali-setup.sh --only recon,sniff

# Listar categorias e ferramentas disponíveis
./kali-setup.sh --list

# Ajuda
./kali-setup.sh --help
```

## Categorias

| Categoria    | Ferramentas principais                                          |
|--------------|-----------------------------------------------------------------|
| `recon`      | nmap, masscan, rustscan, theharvester, recon-ng, whois          |
| `web`        | gobuster, dirb, wfuzz, sqlmap, nikto, whatweb, ffuf, wpscan     |
| `wireless`   | aircrack-ng, reaver, wifite, hcxdumptool                        |
| `exploit`    | metasploit-framework, searchsploit, exploitdb                   |
| `sniff`      | wireshark, tshark, tcpdump, responder, ettercap                 |
| `passwords`  | hydra, john, hashcat, seclists, wordlists, cewl                 |
| `forensics`  | binwalk, foremost, testdisk, steghide, exiftool                 |
| `misc`       | git, curl, wget, vim, tmux, python3, pipx, jq                   |

## O que o script faz

1. ✅ Verifica se o ambiente é compatível (Debian/Kali + sudo)
2. ✅ `apt update` / `upgrade` / `dist-upgrade`
3. ✅ Remove pacotes obsoletos (`autoremove` / `autoclean`)
4. ✅ Instala as categorias escolhidas
5. ✅ Se um pacote falhar, tenta instalar um a um (evita parar tudo)
6. ✅ Gera log em `/var/log/kali-setup.log`

## Logs

```bash
cat /var/log/kali-setup.log
```

## Aviso

Ferramentas de segurança devem ser usadas **apenas em ambientes que você owns ou tem autorização explícita** (laboratórios, CTFs, testes autorizados).

## Licença

MIT
