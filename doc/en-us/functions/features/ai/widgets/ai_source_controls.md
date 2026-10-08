# lib/features/ai/widgets/ai_source_controls.dart

## AI sources and WebDAV privacy

MyApps-AI v0.6.0 is explicitly split into runtime, platform, models, local UI, sources and llama.cpp packages. Settings uses the unified section skeleton. Global source selection is device-local (`aiSourceSelection`), defaults to system AI, and never chooses online as fallback (MyDay has no online sources). The shared `AiSourceRouter` also keeps the device-local keys `aiComputePreference`, `aiGpuFailures`, `aiCustomModels` and `aiModelAliases`, which are never synced and never in backups. Qwen3.5 0.8B/2B Q4_K_M and Gemma 4 E2B Q4_0 run on the CPU, or on the GPU only where verified and turned on; custom GGUF models can be added from a Hugging Face repository after a warning. Downloads require explicit actions, use pinned URLs and SHA-256, and live under `ai_models/` outside data modules, sync, backup and ZIP. Model leases prevent removal during use. Source switches cancel old work and release model resources. Technical details are a complete, copyable report from the router. System proofreading remains independent in MyNihongo.

WebDAV notice version 1 must be acknowledged on each device before connection testing, manual/force sync or background sync. The record is in device-local storage_config.json. Existing configurations stay intact while sync is paused; the WebDAV page displays a review banner. Declining saves no configuration and makes no request. JSON/images have no application-level encryption; HTTPS protects transit, HTTP does not. Wire format, locks and conflict policy remain unchanged.

## Declarations

| Declaration | Purpose |
|---|---|
| `const AiSourceControls({super.key, required this.backend, required this.onSelected})` | Bind the router and the selection callback that pauses the AI service. |
| `Widget build(BuildContext context) {` | Render the shared `MyAppsAiSourceSection` with app labels (no online entry, GPU switch). |
| `Future<void> openAiLocalModels(BuildContext context, AiSourceRouter backend, String? initial) {` | Open the local models page with rename menu and the "Add a custom model" entry. |
| `MyAppsLocalModelLabels _modelLabels(AppLocalizations l, AiSourceRouter backend) =>` | Build list labels; names come from the router (friendly name or alias). |
| `const _ModelMenu({required this.backend, required this.modelId})` | Bind a model to its menu. |
| `Widget build(BuildContext context) {` | Menu with Rename and, for custom models, Remove from list. |
| `const _AliasDialog({required this.modelId})` | Bind a model to the rename dialog. |
| `Widget build(BuildContext context) {` | Build the rename dialog; pops the typed alias on save.
