import os
import joblib
from groq import Groq
from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from dotenv import load_dotenv

load_dotenv()

# 1. ML Model Load
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
model_ml = joblib.load(os.path.join(BASE_DIR, 'disease_model.pkl'))
le = joblib.load(os.path.join(BASE_DIR, 'label_encoder.pkl'))

# 2. ML Prediction Logic
def get_ml_prediction(symptoms_description):
    s_lower = symptoms_description.lower()
    s_input = [
        1 if "fever" in s_lower else 0,
        1 if "cough" in s_lower else 0,
        1 if "fatigue" in s_lower else 0,
        1 if "pain" in s_lower else 0
    ]
    pred = model_ml.predict([s_input])
    return le.inverse_transform(pred)[0]

# 3. Groq API View
@csrf_exempt
@api_view(['POST'])
def ask_doctor(request):
    user_query = request.data.get('query', '').lower()
    
    try:
        # 1. ML Prediction (Sirf reference ke liye)
        predicted_disease = get_ml_prediction(user_query)

        # 2. Groq Client
        client = Groq(api_key=os.getenv("GROQ_API_KEY"))

        # 3. Smart Prompt (AI ko bolo ki ML ke alawa bhi soche)
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": f"""You are an advanced Medical AI. 
                    A basic ML model predicted '{predicted_disease}', but you must analyze the symptoms yourself. 
                    If the user mentions specific things like 'stomach pain', 'rash', or 'breathing issue', 
                    don't just say Flu. Give a detailed and logical medical explanation."""
                },
                {
                    "role": "user",
                    "content": f"User Symptoms: {user_query}"
                }
            ],
            model="llama-3.1-8b-instant",
            temperature=0.7, # Thoda creative banane ke liye
        )

        ai_response = chat_completion.choices[0].message.content

        return JsonResponse({
            "status": "success",
            "ai_response": ai_response
        })

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=500)

# Home view
def home(request):
    return render(request, 'index.html')