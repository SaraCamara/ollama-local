#!/bin/bash

echo "=== [1] Iniciando Ollama para uso com Open WebUI ==="

# Parar qualquer instância anterior do Ollama via systemd
echo "➡ Parando serviço systemd do Ollama (caso esteja rodando)..."
sudo systemctl stop ollama 2>/dev/null

# Iniciar o Ollama expondo externamente na porta 11434
echo "➡ Iniciando ollama com OLLAMA_HOST=0.0.0.0:11434"
OLLAMA_HOST=0.0.0.0:11434 ollama serve &

# Aguarda alguns segundos para o servidor iniciar
sleep 3

# Verifica os modelos disponíveis
echo "➡ Verificando modelos já disponíveis:"
curl -s http://0.0.0.0:11434/api/tags | jq .

# Baixando modelos
echo "➡ Baixando modelos DeepSeek..."
ollama pull deepseek-r1:7b
ollama pull llama
ollama pull gemma:2b

# Puxar imagem atualizada do Open WebUI
echo "➡ Atualizando imagem Docker do Open WebUI..."
sudo docker pull ghcr.io/open-webui/open-webui:main

# Verifica se contêiner já existe
EXISTE=$(sudo docker ps -a -q -f name=open-webui)

if [ "$EXISTE" ]; then
  echo "➡ Contêiner 'open-webui' já existe. Reiniciando..."
  sudo docker rm -f open-webui
fi

# Executar o contêiner Open WebUI
echo "➡ Iniciando contêiner do Open WebUI em http://localhost:3000 ..."
sudo docker run -d -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_HOST=http://host.docker.internal:11434 \
  -e OLLAMA_MODELS=/root/.ollama/models \
  -v open-webui:/app/backend/data \
  --name open-webui --restart always \
  ghcr.io/open-webui/open-webui:main

echo ""
echo "✅ Open WebUI está rodando em: http://localhost:3000"
echo "✅ Ollama (API REST) disponível em: http://0.0.0.0:11434"
echo ""

# Mostrar status dos serviços
echo "➡ Status atual:"
curl -s http://0.0.0.0:11434/api/status | jq .

echo ""
echo "🔍 Para logs do Ollama (via systemd): journalctl -u ollama -f"
echo "🔍 Para logs do Open WebUI: sudo docker logs -f open-webui"
