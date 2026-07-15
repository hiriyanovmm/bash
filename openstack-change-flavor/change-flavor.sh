#!/usr/bin/env bash
set -euo pipefail

VM="${1:-}"
NEW_FLAVOR="${2:-}"
SLEEP_SEC="${3:-10}"
TIMEOUT_SEC="${4:-900}"

if [[ -z "$VM" || -z "$NEW_FLAVOR" ]]; then
  echo "Использование: $0 <vm_name_or_id> <new_flavor> [poll_interval_sec] [timeout_sec]"
  exit 1
fi

command -v openstack >/dev/null 2>&1 || {
  echo "Ошибка: openstack CLI не найден"
  exit 1
}

echo "[*] Проверяю flavor: $NEW_FLAVOR"
openstack flavor show "$NEW_FLAVOR" >/dev/null

OLD_FLAVOR=$(openstack server show "$VM" -f value -c flavor 2>/dev/null || true)
OLD_STATUS=$(openstack server show "$VM" -f value -c status)

echo "[*] Текущий статус ВМ: $OLD_STATUS"
echo "[*] Текущий flavor ВМ: $OLD_FLAVOR"

echo "[*] Запускаю resize ВМ '$VM' -> '$NEW_FLAVOR'"
openstack server resize --flavor "$NEW_FLAVOR" "$VM"

echo "[*] Жду перехода ВМ в статус ACTIVE"
elapsed=0

while true; do
  STATUS=$(openstack server show "$VM" -f value -c status)
  FLAVOR=$(openstack server show "$VM" -f value -c flavor 2>/dev/null || true)

  echo "[*] status=$STATUS flavor=$FLAVOR elapsed=${elapsed}s"

  case "$STATUS" in
    ACTIVE)
      echo "[+] ВМ снова в ACTIVE"
      break
      ;;
    ERROR)
      echo "[!] ВМ перешла в ERROR"
      exit 2
      ;;
    *)
      ;;
  esac

  if (( elapsed >= TIMEOUT_SEC )); then
    echo "[!] Таймаут ожидания ACTIVE (${TIMEOUT_SEC}s)"
    exit 3
  fi

  sleep "$SLEEP_SEC"
  elapsed=$((elapsed + SLEEP_SEC))
done

FINAL_FLAVOR=$(openstack server show "$VM" -f value -c flavor 2>/dev/null || true)

echo "[*] Итоговый flavor: $FINAL_FLAVOR"

if [[ "$FINAL_FLAVOR" == *"$NEW_FLAVOR"* ]]; then
  echo "[+] Flavor успешно изменён на $NEW_FLAVOR"
else
  echo "[!] ВМ стала ACTIVE, но flavor не совпадает с ожидаемым"
  exit 4
fi
