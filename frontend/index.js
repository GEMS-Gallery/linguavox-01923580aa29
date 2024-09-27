import { backend } from 'declarations/backend';

let typingTimer;
const doneTypingInterval = 1000; // 1 second

const inputText = document.getElementById('inputText');
const targetLanguage = document.getElementById('targetLanguage');
const translationOutput = document.getElementById('translationOutput');
const speakButton = document.getElementById('speakButton');
const historyList = document.getElementById('historyList');

inputText.addEventListener('keyup', () => {
    clearTimeout(typingTimer);
    if (inputText.value) {
        typingTimer = setTimeout(translateText, doneTypingInterval);
    }
});

targetLanguage.addEventListener('change', translateText);

speakButton.addEventListener('click', speakTranslation);

async function translateText() {
    const text = inputText.value;
    const lang = targetLanguage.value;

    if (text) {
        try {
            const translation = await backend.translate(text, lang);
            translationOutput.textContent = translation;
            updateHistory();
        } catch (error) {
            console.error('Translation error:', error);
            translationOutput.textContent = 'Error occurred during translation';
        }
    }
}

function speakTranslation() {
    const text = translationOutput.textContent;
    const lang = targetLanguage.value;

    if (text && 'speechSynthesis' in window) {
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.lang = lang;
        speechSynthesis.speak(utterance);
    }
}

async function updateHistory() {
    try {
        const history = await backend.getTranslationHistory();
        historyList.innerHTML = '';
        history.forEach(entry => {
            const li = document.createElement('li');
            li.textContent = `${entry.original} -> ${entry.translated} (${entry.targetLanguage})`;
            historyList.appendChild(li);
        });
    } catch (error) {
        console.error('Error fetching history:', error);
    }
}

// Initial history load
updateHistory();
