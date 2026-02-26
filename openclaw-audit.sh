#!/usr/bin/env bash
# openclaw-audit.sh — Security self-check for OpenClaw installations
# https://github.com/openclawhuber/openclaw-audit
# Run: curl -fsSL https://raw.githubusercontent.com/openclawhuber/openclaw-audit/main/openclaw-audit.sh | bash
# Or:  ./openclaw-audit.sh [path-to-openclaw.json]

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

CRITICAL=0
WARNINGS=0
PASS=0
INFO=0

CONFIG="${1:-$HOME/.openclaw/openclaw.json}"

banner() {
  echo ""
  echo -e "${BOLD}🦞 OpenClaw Security Audit${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

critical() { echo -e "  ${RED}✖ CRITICAL:${NC} $1"; CRITICAL=$((CRITICAL+1)); }
warn()     { echo -e "  ${YELLOW}⚠ WARNING:${NC}  $1"; WARNINGS=$((WARNINGS+1)); }
pass()     { echo -e "  ${GREEN}✔ PASS:${NC}     $1"; PASS=$((PASS+1)); }
info()     { echo -e "  ${BLUE}ℹ INFO:${NC}     $1"; INFO=$((INFO+1)); }

check_config_exists() {
  echo -e "${BOLD}[1/7] Config file${NC}"
  if [[ ! -f "$CONFIG" ]]; then
    critical "Config not found at $CONFIG"
    echo "  Specify path: $0 /path/to/openclaw.json"
    exit 1
  fi
  pass "Config found at $CONFIG"
  echo ""
}

check_telegram_dm_policy() {
  echo -e "${BOLD}[2/7] Telegram DM Policy${NC}"
  local dm_policy
  dm_policy=$(python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
tg = d.get('channels', {}).get('telegram', {})
print(tg.get('dmPolicy', 'NOT_SET'))
" 2>/dev/null || echo "NO_TELEGRAM")

  case "$dm_policy" in
    open)
      critical "Telegram dmPolicy is 'open' — anyone can DM your bot!"
      echo -e "         Fix: Set dmPolicy to 'allowlist' or 'pairing'"
      ;;
    pairing)
      pass "Telegram dmPolicy is 'pairing' (approve-first)"
      ;;
    allowlist)
      pass "Telegram dmPolicy is 'allowlist' (restricted)"
      ;;
    disabled)
      pass "Telegram DMs are disabled"
      ;;
    NOT_SET)
      warn "Telegram dmPolicy is not explicitly set (defaults to 'pairing')"
      echo -e "         Recommendation: Set it explicitly for clarity"
      ;;
    NO_TELEGRAM)
      info "Telegram channel not configured (skipping)"
      ;;
    *)
      warn "Unknown dmPolicy value: $dm_policy"
      ;;
  esac
  echo ""
}

check_telegram_allowfrom() {
  echo -e "${BOLD}[3/7] Telegram allowFrom${NC}"
  local allow_from
  allow_from=$(python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
tg = d.get('channels', {}).get('telegram', {})
af = tg.get('allowFrom', [])
if '*' in af:
    print('WILDCARD')
elif len(af) == 0:
    print('EMPTY')
else:
    print(f'RESTRICTED:{len(af)}')
" 2>/dev/null || echo "NO_TELEGRAM")

  case "$allow_from" in
    WILDCARD)
      critical "Telegram allowFrom contains '*' — all users allowed!"
      echo -e "         Fix: Replace '*' with specific Telegram user IDs"
      ;;
    EMPTY)
      info "Telegram allowFrom is empty (policy-dependent behavior)"
      ;;
    RESTRICTED:*)
      local count="${allow_from#RESTRICTED:}"
      pass "Telegram allowFrom restricted to $count user(s)"
      ;;
    NO_TELEGRAM)
      info "Telegram not configured (skipping)"
      ;;
  esac
  echo ""
}

check_gateway_bind() {
  echo -e "${BOLD}[4/7] Gateway Bind Address${NC}"
  local bind
  bind=$(python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
gw = d.get('gateway', {})
print(gw.get('bind', 'NOT_SET'))
" 2>/dev/null || echo "UNKNOWN")

  case "$bind" in
    loopback|localhost|127.0.0.1|"::1")
      pass "Gateway bound to loopback ($bind) — not exposed to network"
      ;;
    lan|"0.0.0.0"|"")
      warn "Gateway bound to '$bind' — exposed on local network"
      echo -e "         Ensure firewall rules are in place"
      ;;
    tailnet)
      pass "Gateway bound to Tailscale network ($bind)"
      ;;
    NOT_SET)
      info "Gateway bind not explicitly set (check defaults)"
      ;;
    *)
      warn "Unusual gateway bind: $bind — verify this is intended"
      ;;
  esac
  echo ""
}

check_gateway_auth() {
  echo -e "${BOLD}[5/7] Gateway Authentication${NC}"
  local auth_mode
  auth_mode=$(python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
auth = d.get('gateway', {}).get('auth', {})
print(auth.get('mode', 'NOT_SET'))
" 2>/dev/null || echo "UNKNOWN")

  case "$auth_mode" in
    token)
      pass "Gateway auth uses token mode"
      ;;
    none|off|disabled)
      critical "Gateway auth is DISABLED — anyone with network access can control your agent!"
      echo -e "         Fix: Set gateway.auth.mode to 'token'"
      ;;
    NOT_SET)
      warn "Gateway auth mode not explicitly set"
      ;;
    *)
      info "Gateway auth mode: $auth_mode"
      ;;
  esac
  echo ""
}

check_group_policy() {
  echo -e "${BOLD}[6/7] Telegram Group Policy${NC}"
  local group_policy
  group_policy=$(python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
tg = d.get('channels', {}).get('telegram', {})
print(tg.get('groupPolicy', 'NOT_SET'))
" 2>/dev/null || echo "NO_TELEGRAM")

  case "$group_policy" in
    open)
      warn "Telegram groupPolicy is 'open' — any group member can interact"
      echo -e "         Consider 'allowlist' if bot is in public groups"
      ;;
    allowlist)
      pass "Telegram groupPolicy is 'allowlist'"
      ;;
    disabled)
      pass "Telegram group interactions disabled"
      ;;
    NOT_SET)
      info "Telegram groupPolicy not explicitly set (defaults to 'allowlist')"
      ;;
    NO_TELEGRAM)
      info "Telegram not configured (skipping)"
      ;;
  esac
  echo ""
}

check_model_fallbacks() {
  echo -e "${BOLD}[7/7] Model Fallbacks${NC}"
  local fallback_count
  fallback_count=$(python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
fb = d.get('agents', {}).get('defaults', {}).get('model', {}).get('fallbacks', [])
print(len(fb))
" 2>/dev/null || echo "0")

  if [[ "$fallback_count" == "0" ]]; then
    warn "No model fallbacks configured — if primary model is down, you're offline"
    echo -e "         Fix: openclaw models fallbacks add <model>"
  else
    pass "$fallback_count fallback model(s) configured"
  fi
  echo ""
}

summary() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}Summary${NC}"
  echo -e "  ${RED}Critical: $CRITICAL${NC}  ${YELLOW}Warnings: $WARNINGS${NC}  ${GREEN}Pass: $PASS${NC}  ${BLUE}Info: $INFO${NC}"
  echo ""
  if [[ $CRITICAL -gt 0 ]]; then
    echo -e "  ${RED}${BOLD}⚠  ACTION REQUIRED — $CRITICAL critical issue(s) found!${NC}"
  elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "  ${YELLOW}${BOLD}⚡ Pretty good — $WARNINGS item(s) to review${NC}"
  else
    echo -e "  ${GREEN}${BOLD}🛡  Looking solid! No critical issues found.${NC}"
  fi
  echo ""
  echo -e "  ${BLUE}Need help hardening your setup? https://upwork.com/freelancers/openclawhuber${NC}"
  echo -e "  ${BLUE}Guide: https://github.com/openclawhuber/openclaw-audit${NC}"
  echo ""
}

# Run
banner
check_config_exists
check_telegram_dm_policy
check_telegram_allowfrom
check_gateway_bind
check_gateway_auth
check_group_policy
check_model_fallbacks
summary

exit $CRITICAL
