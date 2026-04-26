const promptInput = document.getElementById('prompt');
const generateBtn = document.getElementById('generateBtn');
const copyBtn = document.getElementById('copyBtn');
const loadingEl = document.getElementById('loading');
const resultEl = document.getElementById('result').querySelector('code');

function setLoading(isLoading) {
  loadingEl.classList.toggle('hidden', !isLoading);
  generateBtn.disabled = isLoading;
}

async function generateCode() {
  const prompt = promptInput.value.trim();

  if (!prompt) {
    alert('من فضلك اكتب الطلب أولاً.');
    return;
  }

  setLoading(true);
  copyBtn.disabled = true;
  resultEl.textContent = '// Generating...';

  try {
    const response = await fetch('/generate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ prompt }),
    });

    const text = await response.text();

    if (!response.ok) {
      throw new Error(text || 'Failed to generate code.');
    }

    resultEl.textContent = text;
    copyBtn.disabled = false;
  } catch (error) {
    resultEl.textContent = `// Error: ${error.message}`;
  } finally {
    setLoading(false);
  }
}

async function copyCode() {
  const content = resultEl.textContent;
  if (!content || content.startsWith('// Generated code will appear here')) {
    return;
  }

  try {
    await navigator.clipboard.writeText(content);
    const original = copyBtn.textContent;
    copyBtn.textContent = 'Copied!';
    setTimeout(() => {
      copyBtn.textContent = original;
    }, 1200);
  } catch {
    alert('تعذر النسخ تلقائياً. انسخ الكود يدوياً.');
  }
}

generateBtn.addEventListener('click', generateCode);
copyBtn.addEventListener('click', copyCode);
