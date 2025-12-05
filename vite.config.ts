import { defineConfig, Plugin } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import { fileURLToPath } from "url";

type ImportedModule = { default?: any } & Record<string, any>;

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function tryImportAny(names: string[]): Promise<{ name: string; mod: ImportedModule } | null> {
  for (const name of names) {
    try {
      // dynamic import; TypeScript will infer as any/unknown
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const mod = (await import(name)) as ImportedModule;
      return { name, mod };
    } catch {
      // try next candidate
    }
  }
  return null;
}

function resolvePluginExport(
  imported: { name: string; mod: ImportedModule } | null,
  namedExportCandidates: string[] = []
): { plugin: Plugin | (() => Plugin) | null; source?: string } {
  if (!imported) return { plugin: null };
  const { name, mod } = imported;

  if (mod.default) return { plugin: mod.default as Plugin | (() => Plugin), source: name };

  for (const key of namedExportCandidates) {
    if (mod[key]) return { plugin: mod[key] as Plugin | (() => Plugin), source: `${name}:${key}` };
  }

  // last resort: return module itself if it looks like a plugin
  return { plugin: (mod as unknown) as Plugin, source: name };
}

/** Map Replit package -> fallback candidates (adjust to real npm package names you want) */
const PLUGIN_CANDIDATES: Record<string, string[]> = {
  "@replit/vite-plugin-runtime-error-modal": ["@replit/vite-plugin-runtime-error-modal", "vite-plugin-runtime-error-modal"],
  "@replit/vite-plugin-cartographer": ["@replit/vite-plugin-cartographer", "vite-plugin-cartographer"],
  "@replit/vite-plugin-dev-banner": ["@replit/vite-plugin-dev-banner", "vite-plugin-dev-banner"],
};

export default defineConfig(async () => {
  const plugins: (Plugin | Promise<Plugin>)[] = [react()];

  if (process.env.NODE_ENV !== "production") {
    async function tryAll(replitName: string, namedExports: string[] = []) {
      const candidates = PLUGIN_CANDIDATES[replitName] ?? [replitName];
      const imported = await tryImportAny(candidates);
      if (!imported) {
        // eslint-disable-next-line no-console
        console.warn(`[vite-config] plugin not found: tried ${candidates.join(", ")}`);
        return;
      }

      const resolved = resolvePluginExport(imported, namedExports);
      if (!resolved.plugin) {
        // eslint-disable-next-line no-console
        console.warn(`[vite-config] imported ${imported.name} but no usable export found`);
        return;
      }

      try {
        const maybePlugin = typeof resolved.plugin === "function" ? resolved.plugin() : resolved.plugin;
        plugins.push(maybePlugin);
        // eslint-disable-next-line no-console
        console.info(`[vite-config] using plugin from ${resolved.source}`);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.warn(`[vite-config] failed to initialize plugin from ${resolved.source}:`, err);
      }
    }

    await tryAll("@replit/vite-plugin-runtime-error-modal");
    await tryAll("@replit/vite-plugin-cartographer", ["cartographer"]);
    await tryAll("@replit/vite-plugin-dev-banner", ["devBanner"]);
  }

  return {
    plugins,
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "client", "src"),
        "@shared": path.resolve(__dirname, "shared"),
        "@assets": path.resolve(__dirname, "attached_assets"),
      },
    },
    root: path.resolve(__dirname, "client"),
    build: {
      outDir: path.resolve(__dirname, "dist/public"),
      emptyOutDir: true,
    },
    server: {
      fs: {
        strict: false,
      },
    },
    publicDir: "client/public",
  };
});
