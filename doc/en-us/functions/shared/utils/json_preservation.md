# lib/shared/utils/json_preservation.dart

**Split file.** The generic engine — `JsonPreservation`, `JsonPreservationSchema`, and
`JsonListPreservation` — moved to the `myapps_data` package (`lib/src/json/json_preservation.dart`)
and is re-exported here, so every existing import keeps compiling.

**The field schemas stayed.** They name MyDay's own data fields, which the shared package must never
know about. They are handed to the sync engine through
[`../../app/data_modules.md`](../../app/data_modules.md), which wires them into each module's
pre-upload transform.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `JsonPreservation` / `JsonPreservationSchema` / `JsonListPreservation` | re-export | A | The generic engine, from the package. |
| [`dataFilePreservationSchemas`](#schemas) | constant | A | File name to schema, for all five data files. |
| `_todoDataSchema`, `_financeDataSchema`, `_exchangeRateDataSchema`, `_intimacyDataSchema`, `_weightDataSchema` and their nested item schemas (including `_accountPickerSettingsSchema` and `_intimacyChartSettingsSchema`) | constants | B | Per-model known-key declarations. |

## Documentation

### `dataFilePreservationSchemas` <a id="schemas"></a>
- **Kind:** constant map, file name to `JsonPreservationSchema`
- **Purpose:** Tells the preservation engine which keys each data file legitimately knows about, so
  everything else is treated as an unknown field to carry forward.
- **Notes:** MyDay's merge output is **not** self-preserving — unlike MyAnime and MyDevice, which
  bake `extraJson` into their models. Unknown fields are re-applied at write time from the
  base/local/remote snapshots, in that order. That is why every structured module in the registry
  sets a `preUploadTransform`. Adding a field to a model means adding it to the matching schema here,
  or it will be treated as unknown.

## Where the engine documentation lives

`packages/myapps_data/doc/en-us/functions/src/json/json_preservation.md`.
