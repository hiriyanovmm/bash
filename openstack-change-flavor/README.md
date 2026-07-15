# OpenStack Flavor Resize Script

A Bash script for resizing an OpenStack virtual machine to a new flavor with status monitoring and basic validation.

The script checks the target flavor, starts a resize operation, waits for the VM to return to `ACTIVE`, and verifies that the flavor change was applied successfully.

## Features

- Resizes an OpenStack VM to a new flavor
- Validates that the target flavor exists before starting
- Detects the current VM status and flavor
- Waits for the resize operation to complete
- Handles `ACTIVE` and `ERROR` states
- Supports configurable poll interval and timeout
- Verifies the final flavor after the VM returns to `ACTIVE`

## Usage

```bash
./resize_flavor.sh <vm_name_or_id> <new_flavor> [poll_interval_sec] [timeout_sec]
```

### Arguments

- `vm_name_or_id` — VM name or UUID in OpenStack
- `new_flavor` — Target flavor name
- `poll_interval_sec` — Polling interval in seconds, default: `10`
- `timeout_sec` — Maximum wait time in seconds, default: `900`

## Workflow

1. Validate input parameters.
2. Check that the `openstack` CLI is installed.
3. Verify that the requested flavor exists.
4. Read the current VM status and flavor.
5. Start the resize operation.
6. Poll VM status until it becomes `ACTIVE` or `ERROR`.
7. Check the final flavor.
8. Return success only if the flavor matches the requested one.

## Exit Codes

- `0` — Resize completed successfully
- `1` — Invalid arguments or missing `openstack` CLI
- `2` — VM entered `ERROR` state
- `3` — Timeout while waiting for `ACTIVE`
- `4` — VM became `ACTIVE`, but the final flavor does not match the requested one

## Example

```bash
./change_flavor.sh web01 m1.medium 10 900
```

Example output:

```text
[*] Проверяю flavor: m1.medium
[*] Текущий статус ВМ: ACTIVE
[*] Текущий flavor ВМ: m1.small
[*] Запускаю resize ВМ 'web01' -> 'm1.medium'
[*] Жду перехода ВМ в статус ACTIVE
[*] status=VERIFY_RESIZE flavor=m1.medium elapsed=10s
[*] status=ACTIVE flavor=m1.medium elapsed=20s
[+] ВМ снова в ACTIVE
[*] Итоговый flavor: m1.medium
[+] Flavor успешно изменён на m1.medium
```

## Notes

- The script uses `set -euo pipefail` for safer execution.
- `openstack server resize` may require confirmation depending on cloud policy.
- The final flavor check is done by matching the returned flavor string from OpenStack.
- The script is suitable for automation, change windows, and operational runbooks.

## Requirements

- OpenStack CLI installed and configured
- Access to a project with permission to resize servers
- A valid target flavor available in the current cloud
