
# 🔍 Script de Verificação de DNS Leak e IP Público

Este é um script em Bash que permite verificar se há **vazamento de DNS (DNS Leak)** e também consultar informações detalhadas sobre seu **IP público**, como localização, ASN e provedor.

## 🚀 Funcionalidades

- ✔️ Verificação de vazamento de DNS (DNS Leak).
- ✔️ Consulta do IP público com informações de geolocalização.
- ✔️ Suporte a definição de interface de rede específica (ex.: `eth0`, `wlan0` ou IP local).
- ✔️ Saída colorida e organizada para facilitar a visualização.
- ✔️ Dependências mínimas (Curl, Ping e opcionalmente JQ).

## 📦 Dependências

- `curl`
- `ping`
- `jq` (opcional, para uma saída mais bonita e estruturada)

## 🔧 Instalação

1. Clone o repositório:

```bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
```

2. Dê permissão de execução:

```bash
chmod +x dnsleaktest.sh
```

3. Execute o script:

```bash
./dnsleaktest.sh
```

### ✅ Para rodar especificando uma interface (opcional):

```bash
./dnsleaktest.sh -i eth0
```

## 📝 Exemplo de saída

```
================ INFORMAÇÕES DO IP PÚBLICO ================

Endereço IP:    179.xxx.xxx.xxx
Localização:    São Paulo, SP, BR
Organização:    ASXXXX Claro S/A

============================================================

================ RESULTADO DO TESTE DE DNS =================

IP detectado durante o teste de DNS:
179.xxx.xxx.xxx

✅ Você está utilizando 2 servidores DNS:
8.8.8.8 [United States, AS15169]
1.1.1.1 [United States, AS13335]

🔍 Conclusão:
Nenhum vazamento de DNS detectado.

======================= FIM DO TESTE =======================
```

## ⚠️ Observações

- Se o resultado listar servidores DNS que não são os fornecidos pela sua VPN ou pelos seus servidores DNS configurados, há um possível vazamento de DNS (**DNS Leak**).
- Sempre execute este script após conectar uma VPN para garantir sua privacidade.

## 🧠 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais informações.
