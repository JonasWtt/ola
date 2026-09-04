# Local AI Setup with vLLM and Odysseus

A complete Docker Compose setup for running local AI models with vLLM and Odysseus AI platform on an RTX 4060 (8GB VRAM).

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- NVIDIA Container Toolkit installed
- NVIDIA drivers for RTX 4060
- At least 16GB RAM (32GB recommended for better performance)

### Installation

1. **Clone this repository:**
```bash
git clone https://github.com/JonasWtt/ola.git
cd ola
```

2. **Start a vLLM server** (choose one model):
```bash
# For example, start Llama 3 8B:
docker compose -f docker-compose.vllm.llama3-8b.yml up -d
```

3. **Start Odysseus AI:**
```bash
# For simple LAN access (bound to 0.0.0.0):
docker compose -f docker-compose.simple.yml up -d

# OR for more control:
docker compose -f docker-compose.odysseus.yml up -d
```

4. **Access the platforms:**
- **vLLM Server:** `http://localhost:8000` (OpenAI-compatible API)
- **Odysseus AI:** `http://localhost:7000` (Web UI)

## 📚 Available Models

We provide optimized Docker Compose configurations for several models that work well on an RTX 4060 with 8GB VRAM:

### 🏆 Recommended Models

| Model | File | VRAM Usage | Context Length | Best For |
|-------|------|------------|----------------|----------|
| **Phi-3 Mini** | `docker-compose.vllm.phi-3-mini.yml` | ~4.5GB | 4096 | Coding, mathematical reasoning |
| **LFM2.5-8B-A1B** | `docker-compose.vllm.lfm2-5-8b-a1b.yml` | ~6.0GB | 128000 | **DevOps, reasoning, fastest** ⭐ |
| **CodeQwen 7B** | `docker-compose.vllm.codeqwen-7b.yml` | ~6.2GB | 8192 | **DevOps/Coding** ⭐ |
| **Qwen2 7B** | `docker-compose.vllm.qwen2-7b.yml` | ~6.2GB | 8192 | Long context, coding, reasoning |
| **Devstral Small 2** | `docker-compose.vllm.devstral-small.yml` | ~6.5GB | 8192 | **DevOps/Coding** ⭐ |
| **Mistral 7B** | `docker-compose.vllm.mistral-7b-optimized.yml` | ~6.5GB | 4096 | General use, balanced performance |
| **Llama 3 8B** | `docker-compose.vllm.llama3-8b.yml` | ~6.8GB | 4096 | Best overall performance, conversation |
| **Mistral 7B** | `docker-compose.vllm.yml` | ~6.5GB | 8192 | Original config with tool calling |

### 🎯 Model Selection Guide

#### **LFM2.5-8B-A1B** - BEST for DevOps & Speed
- **Strengths:** Mixture-of-Experts (only 1.5B active params), 128K context, 2-3x faster than dense 8B
- **Use Cases:** DevOps, reasoning, fast chat, coding
- **VRAM:** ~6.0GB
- **Speed:** ⚡ **Fastest** (2-3x faster than dense models)

#### **CodeQwen 1.5 7B** - Best for Coding
- **Strengths:** Optimized for code generation, understanding, and debugging
- **Use Cases:** Code completion, debugging, Python, JavaScript, shell scripts
- **VRAM:** ~6.2GB
- **Note:** Qwen's coding-specialized model

#### **Qwen2 7B Instruct** - Best for Long Context
- **Strengths:** Superior reasoning, handles long conversations well, strong coding ability
- **Use Cases:** Document analysis, long-form content, coding assistance
- **VRAM:** ~6.2GB with 8K context
- **Note:** Can handle longer documents and maintain context better than others

#### **Devstral Small 2** - Best for DevOps with Tool Calling
- **Strengths:** Community-optimized, tool calling support, good for automation
- **Use Cases:** DevOps, scripting, automation, tool calling
- **VRAM:** ~6.5GB
- **Features:** Auto tool choice and Hermes parser enabled

#### **Llama 3 8B Instruct** - Best All-Rounder
- **Strengths:** Excellent instruction following, natural conversation, general knowledge
- **Use Cases:** Chatbots, general Q&A, content generation
- **VRAM:** ~6.8GB with 4K context
- **Speed:** Fast and responsive

#### **Mistral 7B** - Original with Tool Calling
- **Strengths:** Tool calling support, good general performance
- **Use Cases:** When you need function/tool calling capabilities
- **VRAM:** ~6.5GB
- **Features:** Auto tool choice and Hermes parser enabled

## 🔄 Dynamic Model Switching (Advanced)

For switching models **without restarting Odysseus**, use the dynamic setup:

### Setup:
1. Start the dynamic vLLM server:
```bash
docker compose -f docker-compose.vllm.dynamic.yml up -d
```

2. Start the model switch server:
```bash
python scripts/model-switch.py
```

3. Switch models via API:
```bash
# Switch to Llama 3 8B
curl -X POST http://localhost:8001/switch \
  -H 'Content-Type: application/json' \
  -d '{"model": "llama3-8b"}'

# Switch to CodeQwen 7B
curl -X POST http://localhost:8001/switch \
  -H 'Content-Type: application/json' \
  -d '{"model": "codeqwen-7b"}'
```

### Available Model Names for Switching:
- `lfm2-5-8b-a1b` - LFM2.5-8B-A1B (default)
- `codeqwen-7b` - CodeQwen 1.5 7B
- `llama3-8b` - Llama 3 8B
- `qwen2-7b` - Qwen2 7B
- `mistral-7b` - Mistral 7B
- `phi-3-mini` - Phi-3 Mini
- `devstral-small` - Devstral Small 2

### Model Switch Server API Endpoints:
- `GET /models` - List all available models
- `GET /current` - Get current model
- `POST /switch` - Switch to a different model
- `GET /health` - Health check

**Note:** Model switching takes 10-30 seconds as it stops and restarts the vLLM container with the new model.

## 🔧 Configuration Options

### Starting a Different Model

To switch models, stop the current vLLM server and start a new one:

```bash
# Stop current server
docker compose -f docker-compose.vllm.llama3-8b.yml down

# Start a different model
docker compose -f docker-compose.vllm.qwen2-7b.yml up -d
```

### Connecting Odysseus to Different Models

The Odysseus configuration is pre-set to connect to `host.docker.internal:8000`. If you change the port or use a different host:

1. Stop Odysseus:
```bash
docker compose -f docker-compose.simple.yml down
```

2. Edit `docker-compose.simple.yml` and update:
```yaml
environment:
  - LLM_HOST=your-host
  - LLM_PORT=your-port
```

3. Restart Odysseus:
```bash
docker compose -f docker-compose.simple.yml up -d
```

## ⚠️ Troubleshooting

### Common Issues and Solutions

#### **1. NVIDIA Runtime Not Available**

**Symptom:** `docker: Error response from daemon: could not select device driver...`

**Solution:**
```bash
# Install NVIDIA Container Toolkit
sudo ./scripts/install-nvidia.sh

# Verify installation
nvidia-smi
nvidia-container-cli --version
```

#### **2. Out of Memory Errors**

**Symptom:** `CUDA out of memory` or container crashes

**Solutions:**
- **Reduce context length:** Edit the compose file and change `--max-model-len` to 2048 or 1024
- **Lower GPU utilization:** Change `--gpu-memory-utilization` from 0.8 to 0.6
- **Switch to a smaller model:** Try Phi-3 Mini (4.5GB) or Qwen2 7B (6.2GB)
- **Close other GPU applications:** Ensure no other programs are using GPU memory

#### **3. Model Download Fails**

**Symptom:** `HuggingFace download errors` or timeouts

**Solutions:**
- **Check internet connection:** Ensure you have stable internet
- **Set HF_TOKEN:** Create a HuggingFace account, get a token, and add to compose file:
```yaml
environment:
  - HF_TOKEN=your_huggingface_token
```
- **Pre-download models:** Download models manually first:
```bash
huggingface-cli download TheBloke/Mistral-7B-Instruct-v0.2-AWQ --local-dir ~/.cache/huggingface
```
- **Use a mirror:** Try using a different HuggingFace mirror

#### **4. Docker Permission Issues**

**Symptom:** `Permission denied` when accessing volumes

**Solutions:**
```bash
# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Fix volume permissions
sudo chown -R $USER:$USER ~/.cache/huggingface
```

#### **5. Port Already in Use**

**Symptom:** `port is already allocated`

**Solutions:**
- **Find and kill the process:**
```bash
sudo lsof -i :8000
sudo kill -9 <PID>
```
- **Change the port:** Edit the compose file and change the port mapping

#### **6. Odysseus Can't Connect to vLLM**

**Symptom:** Odysseus shows connection errors or can't find models

**Solutions:**
- **Verify vLLM is running:**
```bash
curl http://localhost:8000/v1/models
```
- **Check container logs:**
```bash
docker compose -f docker-compose.vllm.llama3-8b.yml logs
```
- **Test direct API call:**
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "llama-3-8b-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
```
- **Verify Docker network:** Ensure both containers can communicate via `host.docker.internal`

#### **7. Slow Performance**

**Symptom:** Very slow token generation

**Solutions:**
- **Reduce context length:** Shorter context = faster generation
- **Use smaller models:** Phi-3 Mini is the fastest
- **Check GPU utilization:**
```bash
nvidia-smi
```
- **Increase GPU memory utilization:** Try 0.85-0.9 if you have headroom
- **Enable KV cache:** vLLM uses KV cache by default for better performance

#### **8. Container Starts but Immediately Exits**

**Symptom:** Container starts and stops within seconds

**Solutions:**
- **Check logs:**
```bash
docker logs <container-name>
```
- **Common causes:**
  - Invalid model name
  - Insufficient GPU memory
  - Missing NVIDIA runtime
  - Corrupted model files
- **Try a different model:** Test with Phi-3 Mini first

#### **9. High CPU Usage**

**Symptom:** CPU at 100% even when idle

**Solutions:**
- **This is normal during model loading:** First run downloads and loads the model
- **After loading, CPU should drop:** If it stays high, there might be an issue
- **Check memory usage:**
```bash
docker stats
```
- **Limit CPU:** Add CPU limits to compose file:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
```

#### **10. Model Not Found in Odysseus**

**Symptom:** Odysseus doesn't show the model or gives "model not found" error

**Solutions:**
- **Verify model name:** Check the exact model name in vLLM's API:
```bash
curl http://localhost:8000/v1/models
```
- **Update Odysseus config:** In Odysseus UI, go to Settings > Model Providers and configure the vLLM endpoint
- **Use correct model identifier:** The model ID might be different from the HuggingFace name

### Debugging Commands

#### Check GPU Status
```bash
# NVIDIA GPU status
nvidia-smi

# GPU memory usage
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

#### Check Docker Status
```bash
# List running containers
docker ps

# View logs
docker compose -f <file>.yml logs -f

# Check resource usage
docker stats
```

#### Test vLLM API
```bash
# List models
curl http://localhost:8000/v1/models

# Test completion
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<your-model-name>",
    "messages": [{"role": "user", "content": "Hello, how are you?"}],
    "max_tokens": 50
  }'
```

#### Check Disk Space
```bash
# Check HuggingFace cache size
du -sh ~/.cache/huggingface

# Clean old models (be careful!)
rm -rf ~/.cache/huggingface/hub/*
```

### Performance Tuning

#### For Better Speed
```yaml
# In compose file, add:
command: [
  "--model", "model-name",
  "--quantization", "awq",
  "--gpu-memory-utilization", "0.85",  # Increase if you have headroom
  "--max-model-len", "2048",           # Reduce for speed
  "--dtype", "auto",
  "--tensor-parallel-size", "1"
]
```

#### For Longer Context
```yaml
# In compose file, adjust:
command: [
  "--model", "model-name",
  "--quantization", "awq",
  "--gpu-memory-utilization", "0.7",   # Lower to leave room
  "--max-model-len", "8192",           # Increase context
  "--dtype", "auto"
]
```

#### For Lower Memory Usage
```yaml
# Use a smaller model and lower settings
command: [
  "--model", "microsoft/Phi-3-mini-4k-instruct-awq",
  "--quantization", "awq",
  "--gpu-memory-utilization", "0.6",
  "--max-model-len", "1024",
  "--dtype", "auto"
]
```

## 📊 Model Comparison for RTX 4060

| Model | VRAM Usage | Speed | Quality | Context | Best For |
|-------|------------|-------|---------|---------|----------|
| Phi-3 Mini | ~4.5GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 4K | ⭐⭐⭐⭐⭐ | Coding |
| LFM2.5-8B-A1B | ~6.0GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 128K | ⭐⭐⭐⭐⭐ | **DevOps/Reasoning** |
| Qwen2 7B | ~6.2GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 8K | ⭐⭐⭐⭐ | Long context |
| CodeQwen 7B | ~6.2GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 8K | ⭐⭐⭐⭐⭐ | **Coding** |
| Devstral Small 2 | ~6.5GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 8K | ⭐⭐⭐⭐⭐ | **DevOps/Tool Calling** |
| Mistral 7B | ~6.5GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 4K | ⭐⭐⭐⭐ | General |
| Llama 3 8B | ~6.8GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 4K | ⭐⭐⭐⭐⭐ | Best overall |

## 🔄 Switching Between Models

1. **Stop current vLLM server:**
```bash
docker compose -f docker-compose.vllm.<current-model>.yml down
```

2. **Start new model:**
```bash
docker compose -f docker-compose.vllm.<new-model>.yml up -d
```

3. **Restart Odysseus (if needed):**
```bash
docker compose -f docker-compose.simple.yml restart
```

## 📝 Notes

- **First run:** Model download may take 5-30 minutes depending on your internet speed
- **Subsequent runs:** Models are cached, so startup is much faster
- **Multiple models:** You can run multiple vLLM servers on different ports if you have enough VRAM
- **Odysseus configuration:** The Odysseus compose file is configured to work with any vLLM server on port 8000

## 📞 Getting Help

If you encounter issues not covered in this guide:

1. **Check the logs first:** Most issues are visible in container logs
2. **Search online:** Many common issues have solutions on GitHub or Stack Overflow
3. **Verify your setup:** Ensure Docker, NVIDIA drivers, and Container Toolkit are properly installed
4. **Try a different model:** Some models may have specific requirements

## 🎉 Success Checklist

- [ ] Docker and Docker Compose installed
- [ ] NVIDIA Container Toolkit installed
- [ ] vLLM server starts without errors
- [ ] Model downloads successfully
- [ ] API responds at `http://localhost:8000/v1/models`
- [ ] Odysseus starts and can connect to vLLM
- [ ] You can chat with the model in Odysseus

Happy AI-ing! 🤖
