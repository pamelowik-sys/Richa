# Richa — CPU Mining + AI Network Stack

Два инструмента в одном Docker Compose:

| Сервис | Что делает | Награда | Нужно для старта |
|---|---|---|---|
| **XMRig** | Майнит Monero (XMR) | XMR | Monero-кошелёк |
| **Bittensor** | Нода ИИ-сети | TAO | Ничего (testnet бесплатно) |

Работает на любом Linux-сервере или ПК. Без облака. Нагрузка ≤ 30% CPU.

---

## Быстрый старт

### 1. Бенчмарк — проверить железо (1-3 минуты)

```bash
git clone https://github.com/pamelowik-sys/Richa.git
cd Richa
docker compose build
docker compose up xmrig-benchmark
```

Показывает реальный hashrate твоего процессора.

### 2. Bittensor — ИИ-нода (бесплатный testnet)

```bash
docker compose up bittensor-test
```

Создаёт кошелёк, подключается к ИИ-сети Bittensor, показывает адрес ноды.
Работает без регистрации и без TAO — идеально для демо инвесторам.

---

## Монетизация: два потока дохода

### Поток 1 — Monero (XMR)

```bash
# Создай кошелёк: https://www.getmonero.org/downloads/#gui
# Затем:
WALLET_ADDRESS=твой_xmr_адрес docker compose up xmrig-miner
```

Hashrate ограничен 30% CPU. Работает на любом железе.

**Сколько зарабатывает при разном масштабе:**

```bash
python3 projection.py --hashrate 5000 --users 1000,10000,100000,1000000
```

### Поток 2 — Bittensor TAO (ИИ-сеть)

Bittensor — это децентрализованная сеть, которая платит токенами TAO за вклад в ИИ. Каждая нода выполняет задачи (отвечает на запросы, обрабатывает данные) и получает TAO пропорционально качеству работы.

```bash
# Тестнет (бесплатно, для демо)
docker compose up bittensor-test

# Мейннет (требует TAO для регистрации)
BT_WALLET=richa docker compose up bittensor-main
```

**Текущая цена TAO:** https://taostats.io

**Чтобы начать на мейннете:**
1. Купи TAO на бирже (MEXC, Bitget, Gate.io)
2. Переведи на coldkey-адрес из вывода `bittensor-test`
3. Зарегистрируй ноду: цена регистрации — на https://taostats.io/subnets
4. Запусти `docker compose up bittensor-main`

---

## Все команды

```bash
# Измерить hashrate
docker compose up xmrig-benchmark

# Майнинг Monero
WALLET_ADDRESS=<адрес> docker compose up xmrig-miner

# Bittensor testnet (демо, бесплатно)
docker compose up bittensor-test

# Bittensor mainnet
docker compose up bittensor-main

# Прогноз заработка для инвесторов
python3 projection.py --hashrate <H/s из бенчмарка>
python3 projection.py --hashrate 8000 --users 100000,500000,1000000
```

---

## Переменные окружения

### XMRig
| Переменная | По умолчанию | Описание |
|---|---|---|
| `WALLET_ADDRESS` | — | Monero-адрес (только для `xmrig-miner`) |
| `POOL` | `pool.supportxmr.com:3333` | Майнинг-пул |
| `MAX_CPU_USAGE` | `30` | Максимум CPU в % |
| `THREADS` | `0` (авто) | Число потоков |

### Bittensor
| Переменная | По умолчанию | Описание |
|---|---|---|
| `NETWORK` | `test` | `test` или `main` |
| `BT_WALLET` | `richa` | Имя кошелька |
| `BT_HOTKEY` | `default` | Имя hotkey |
| `BT_NETUID` | `1` | Номер субсети |

---

## Железо и производительность

| Тир | Ядра | RAM | XMRig потоков | Ожидаемый hashrate |
|---|---|---|---|---|
| STRONG | 8+ | 4+ GB | 2-3 | 10 000–25 000 H/s |
| MEDIUM | 4+ | 2+ GB | 1 | 3 000–8 000 H/s |
| WEAK | 2+ | 1+ GB | 1 | 1 000–3 000 H/s |
| MINIMAL | 1 | любая | 1 | 500–1 000 H/s |

Скрипт определяет тир **автоматически** при каждом запуске.

**+20% к hashrate** — включить huge pages на хосте:
```bash
sudo sysctl -w vm.nr_hugepages=1280
```

---

## Структура репозитория

```
Richa/
├── Dockerfile           — XMRig 6.22.2 (linux/amd64 + arm64)
├── mine.sh              — адаптивный запуск: hardware scan + 30% cap
├── config.json          — конфиг XMRig
├── docker-compose.yml   — все сервисы
├── projection.py        — калькулятор заработка
├── bittensor/
│   ├── Dockerfile       — Bittensor SDK + Python 3.11
│   ├── wallet_setup.sh  — создание cold/hotkey
│   └── bittensor_run.sh — запуск ноды (testnet / mainnet)
└── README.md
```

---

## Важно

- Майнинг и Bittensor-нода на чужих устройствах требуют **явного opt-in** от пользователя
- Кошелёк Bittensor хранится в Docker volume `bittensor-wallet` — не удаляй его
- Mnemonic фразу coldkey нужно сохранить при первом создании — она показывается один раз
