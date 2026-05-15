# Venice.ai API Reference

## Base URL

```
https://api.venice.ai/api/v1
```

## Authentication

All requests require a Bearer token in the `Authorization` header:

```
Authorization: Bearer <api-key>
```

API keys are obtained from the Venice.ai dashboard and should be treated as secrets.

---

## Endpoints

### GET /billing/balance

Get current balance information for the authenticated user. Returns remaining DIEM/USD balances and total DIEM epoch allocation for calculating usage percentage.

**Request:**

```
GET /api/v1/billing/balance
Authorization: Bearer <api-key>
```

No request body or query parameters.

**Response (200):**

```json
{
  "canConsume": true,
  "consumptionCurrency": "DIEM",
  "balances": {
    "diem": 90.5,
    "usd": 25
  },
  "diemEpochAllocation": 100
}
```

| Field | Type | Description |
|---|---|---|
| `canConsume` | `boolean` | Whether the user has sufficient balance to make API requests |
| `consumptionCurrency` | `string \| null` | The currency used for consumption. One of: `USD`, `VCU`, `DIEM`, `BUNDLED_CREDITS` |
| `balances.diem` | `number \| null` | Remaining DIEM balance for current epoch. Null if not staking |
| `balances.usd` | `number \| null` | Remaining USD balance. Null if not available |
| `diemEpochAllocation` | `number` | Total DIEM allocation for the current epoch (from staking). Use with `balances.diem` to calculate usage percentage |

**Usage percentage:**

```
(diemEpochAllocation - balances.diem) / diemEpochAllocation * 100
```

**Error responses:**

| Status | Description |
|---|---|
| `401` | Authentication failed — missing or invalid API key |
| `500` | Internal server error |

---

## Notes

- The Billing API is in **beta** and may change without notice.
- Venice.ai also supports **x402 wallet** authentication (USDC on Base / DIEM staking) as an alternative to API keys — not yet implemented in this widget.
