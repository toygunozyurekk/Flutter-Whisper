from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv 
import os 
from openai import OpenAI, OpenAIError
from tempfile import NamedTemporaryFile


load_dotenv()
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

app = Flask(__name__)
CORS()

client = OpenAI()



@app.route('/openai_response',methods = ['POST'])
def openai_response():
    query = request.json.get('query','')

    response = client.chat.completions.create(
        model='gpt-4',
        messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": query}
            ]
    )

    chat_response = response.choices[0].message.content
    return {'response': chat_response}

    
@app.route('/whisper', methods=['POST'])
def handle_voice_and_get_response():
    results = []
    for filename, handle in request.files.items():
            temp = NamedTemporaryFile(suffix=".",delete=False)
            handle.save(temp)
            
            with open(temp.name, "rb") as audio_file:
                transcription = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file
                )
                transcript = transcription.text 
                openai_response = get_openai_text_response(transcript)
                
                results.append({
                    'filename': filename,
                    'transcript': transcript,
                    'openai_response': openai_response
                })
    return results



def get_openai_text_response(query):
    if not query:
        return {'error': "Message is required."}

    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": query}
            ]
        )
        chat_response = response['choices'][0]['message']['content']
        return {'response': chat_response}

    except OpenAIError as e:
        print(f"Error getting OpenAI response: {str(e)}")  # Log OpenAI response errors
        return {'error': str(e)}




if __name__ == '__main__':
    app.run(debug=True)
