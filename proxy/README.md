# Gemini Proxy — ejemplo Cloud Run / Cloud Functions

Este proxy evita exponer `GEMINI_API_KEY` en el binario de la app.

## Flujo
App --(GEMINI_PROXY_URL)--> Proxy (custodia key) --> generativelanguage.googleapis.com

## Deploy ejemplo (Node.js)
```js
// index.js - Cloud Function v2
import express from 'express';
const app = express();
app.use(express.json());

app.post('/analyze', async (req, res) => {
  const apiKey = process.env.GEMINI_API_KEY; // solo en backend
  const {parts, generationConfig} = req.body;
  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
    {method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({contents:[{parts}], generationConfig})}
  );
  const data = await r.json();
  // Opcional: cache, rate-limit, validación, logging
  res.status(r.status).json(data);
});

app.listen(8080);
```

## Uso en la app
```bash
flutter run --dart-define=GEMINI_PROXY_URL=https://tu-proxy.com
flutter build apk --dart-define=GEMINI_PROXY_URL=https://tu-proxy.com
```

Cuando `GEMINI_PROXY_URL` está definido, `GeminiService` (`lib/services/gemini_service.dart:14`) usa el proxy y **no** requiere `GEMINI_API_KEY` en el cliente.
