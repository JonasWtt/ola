# ⚡ Quick Start - Simple Local AI Setup

This guide gets you running **fast** with minimal complexity. All services bind to `0.0.0.0` so you can access from any device on your home network.

## 🚀 The Simplest Way (Recommended)

### Step 1: Start Odysseus (All-in-One)

```bash
# Start Odysseus + all dependencies (search, memory, notifications)
docker compose -f docker-compose.simple.yml up -d
```

That's it! One command starts everything.

### Step 2: Start a Model Server (Pick One)

Choose **one** model to start with:

```bash
# Option A: Llama 3 8B (Best all-rounder)
docker compose -f docker-compose.vllm.llama3-8b.yml up -d

# Option B: Qwen2 7B (Best for long context)
docker compose -f docker-compose.vllm.qwen2-7b.yml up -d

# Option C: Phi-3 Mini (Best for coding, smallest)
docker compose -f docker-compose.vllm.phi-3-mini.yml up -d

# Option D: Mistral 7B (Original with tool calling)
docker compose -f docker-compose.vllm.yml up -d
```

### Step 3: Access from Any Device

- **On your PC:** Open `http://localhost:7000`
- **On phone/tablet:** Open `http://<your-pc-ip>:7000`

**Find your PC's IP address:**
- Windows: `ipconfig` (look for IPv4 Address)
- Mac/Linux: `ip a` or `ifconfig`

### Step 4: Log In

- **Username:** `admin`
- **Password:** Check with:
  ```bash
  docker compose -f docker-compose.simple.yml logs odysseus | grep "Password:"
  ```

## 📱 Access from Other Devices

Once running, you can access from:
- **Phone/Tablet:** Browser at `http://<your-pc-ip>:7000`
- **Other computers:** Browser at `http://<your-pc-ip>:7000`
- **Same PC:** `http://localhost:7000`

**Important:** Make sure your PC's firewall allows connections on port 7000.

## 🔄 Switching Models

To change models:

```bash
# Stop current model
docker compose -f docker-compose.vllm.llama3-8b.yml down

# Start a different model
docker compose -f docker-compose.vllm.qwen2-7b.yml up -d
```

Odysseus will automatically connect to whichever model is running on port 8000.

## 🛑 Stop Everything

```bash
# Stop all services
docker compose -f docker-compose.simple.yml down
docker compose -f docker-compose.vllm.*.yml down
```

## 📊 What's Running

| Service | Port | Purpose |
|---------|------|---------|
| Odysseus | 7000 | Main AI web interface |
| vLLM | 8000 | Model server (OpenAI API) |
| SearXNG | 8080 | Search engine |
| ChromaDB | 8100 | AI memory storage |
| ntfy | 8091 | Notifications |

## 🎯 Which Model Should You Use?

| Model | VRAM | Best For | Speed |
|-------|------|----------|-------|
| **Phi-3 Mini** | ~4.5GB | Coding, math | ⚡ Fastest |
| **Qwen2 7B** | ~6.2GB | Long conversations, documents | ⚡ Fast |
| **Llama 3 8B** | ~6.8GB | General use, chat | ⚡ Fast |
| **Mistral 7B** | ~6.5GB | General use, tools | ⚡ Fast |
| **Gemma 2 9B** | ~7.5GB | Creative tasks | Fast |

**For RTX 4060 (8GB VRAM):** All models above work well. Start with **Llama 3 8B** for best overall experience.

## 🔧 Troubleshooting

### "Can't connect to server"
- Make sure Docker is running: `docker ps`
- Check if services are up: `docker compose -f docker-compose.simple.yml ps`
- Try accessing from the same PC first: `http://localhost:7000`

### "Model not found"
- Make sure vLLM is running: `docker ps | grep vllm`
- Check vLLM logs: `docker compose -f docker-compose.vllm.llama3-8b.yml logs`
- Wait for model download (can take 10-30 minutes first time)

### "Connection refused"
- Check your PC's firewall settings
- Make sure you're using the correct IP address
- Try `http://localhost:7000` from the same PC

### Get Admin Password
If you lost the password:
```bash
docker compose -f docker-compose.simple.yml logs odysseus | grep -i "password"
```

## 💡 Tips

1. **First run takes time** - Models need to download (5-30 minutes depending on internet)
2. **Use the same model** - Switching models requires re-downloading
3. **Bookmark the IP** - Your PC's local IP usually stays the same
4. **Check GPU usage** - Run `nvidia-smi` to see if GPU is being used

## 🎉 That's It!

You now have a fully functional local AI setup accessible from any device on your home network. No complex configuration needed!
