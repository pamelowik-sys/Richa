# Richa — Monero Mining Engine

CPU-майнер на базе **XMRig** + калькулятор проекций для инвесторов.
Запускается на любом Linux-сервере через Docker, без облачных ресурсов.

---

## Быстрый старт — Бенчмарк

```bash
docker build -t richa-xmrig .
docker run --rm --shm-size=256m richa-xmrig
```

Выводит измеренный hashrate (H/s) через 1-3 минуты.

---

## Проекция заработка для инвесторов

```bash
# Установи Python 3.8+, затем:
python3 projection.py --hashrate 9000

# С кастомной ценой XMR и сценариями пользователей
python3 projection.py --hashrate 9000 --xmr-price 180 \
    --users 10000,100000,1000000,5000000
```

Пример вывода при 9000 H/s:
```
  МАСШТАБ         Hashrate     % сети      в день      в месяц           в год
  1M пользователей  9.00 GH/s  281.25%    $99.47K       $2.98M          $36.31M
  5M пользователей 45.00 GH/s 1406.25%   $497.34K      $14.92M         $181.53M
```

---

## Реальный майнинг

```bash
# 1. Создай Monero-кошелёк: https://www.getmonero.org/downloads/#gui
# 2. Запусти майнер:
docker run --rm --shm-size=256m \
    -e MODE=mine \
    -e WALLET_ADDRESS=твой_адрес_xmr \
    richa-xmrig

# Или через docker compose:
WALLET_ADDRESS=твой_адрес docker compose up miner
```

---

## Переменные окружения

| Переменная | По умолчанию | Описание |
|---|---|---|
| `MODE` | `benchmark` | `benchmark` или `mine` |
| `WALLET_ADDRESS` | — | Monero-адрес (нужен только для `mine`) |
| `POOL` | `pool.supportxmr.com:3333` | Адрес пула |
| `THREADS` | `0` (все ядра) | Кол-во потоков |
| `BENCH_SIZE` | `1M` | Размер датасета |

---

## Системные требования

| | Минимум | Оптимально |
|---|---|---|
| OS | Linux x64 / arm64 | Ubuntu 22.04 |
| Docker | 20.10+ | 24+ |
| CPU | 2 ядра | 8+ ядер |
| RAM | 4 GB | 8+ GB |

### +20% к hashrate (huge pages на хосте)
```bash
sudo sysctl -w vm.nr_hugepages=1280
echo "vm.nr_hugepages=1280" | sudo tee -a /etc/sysctl.conf
```

---

## Важно

Майнинг на машинах пользователей требует явного **opt-in** согласия.
Интеграция в игру должна содержать:
- Экран согласия при первом запуске
- Видимый индикатор активного майнинга в интерфейсе
- Возможность отключить в настройках в любой момент
