import express, { type Request, Response, NextFunction } from "express";
import apiApp from "./api"; // adjust path if server is in /server and api in /api
import { registerRoutes } from "./routes";
import { setupVite, serveStatic, log } from "./vite";
import { initializeMacros } from "./init-macros";
import { validateConfig } from "./config";

const app = express();
// existing middleware, vite setup, static serving...
app.use("/api", apiApp);

declare module 'http' {
  interface IncomingMessage {
    rawBody: unknown
  }
}

app.use(express.json({
  verify: (req, _res, buf) => {
    req.rawBody = buf;
  }
}));
app.use(express.urlencoded({ extended: false }));

app.use((req, res, next) => {
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
});

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse)}`;
      }

      if (logLine.length > 80) {
        logLine = logLine.slice(0, 79) + "…";
      }

      log(logLine);
    }
  });

  next();
});

(async () => {
  console.log('\n' + '='.repeat(60));
  console.log('AHK Script Finder - Server Starting');
  console.log('='.repeat(60));
  
  const { warnings, errors } = validateConfig();
  
  if (errors.length > 0) {
    console.log('\nConfiguration Errors:');
    errors.forEach(error => console.log('  ERROR: ' + error));
  }
  
  if (warnings.length > 0) {
    console.log('\nConfiguration Warnings:');
    warnings.forEach(warning => console.log('  WARNING: ' + warning));
  }
  
  console.log('='.repeat(60) + '\n');
  
  await initializeMacros();
  
  const server = await registerRoutes(app);

  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";

    res.status(status).json({ message });
    if (app.get("env") === "development") {
      console.error(err);
    }
  });

  if (app.get("env") === "development") {
    await setupVite(app, server);
  } else {
    serveStatic(app);
  }

  const port = parseInt(process.env.PORT || '5000');
  app.listen(port, () => console.log(`listening on ${port}`));
  server.listen({
    port,
    host: "0.0.0.0",
  }, () => {
    log(`Server running on port ${port}`);
    log(`Environment: ${app.get("env")}`);
    log(`Bound to: 0.0.0.0:${port}`);
  });
})();
