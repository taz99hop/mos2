const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = 'YOUR_API_KEY_HERE';
const GEMINI_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

app.use(express.json({ limit: '1mb' }));
app.use(express.static(path.join(__dirname)));

app.post('/generate', async (req, res) => {
  try {
    const { prompt } = req.body;

    if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
      return res.status(400).send('Prompt is required.');
    }

    const response = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text: `You are an expert FiveM (QBCore) Lua developer. Return only code with concise inline comments when needed.\n\nUser request:\n${prompt.trim()}`,
              },
            ],
          },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini API error:', errorText);
      return res.status(500).send('Failed to generate code.');
    }

    const data = await response.json();
    const output =
      data?.candidates?.[0]?.content?.parts
        ?.map((part) => part.text)
        .join('\n')
        .trim() || 'No content returned from model.';

    return res.send(output);
  } catch (error) {
    console.error('Server error:', error);
    return res.status(500).send('Unexpected server error.');
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
