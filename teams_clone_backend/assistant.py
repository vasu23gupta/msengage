import datetime
import os
import smtplib
import sys
import json

def wishMe():
    hour = int(datetime.datetime.now().hour)
    if hour>=0 and hour<12:
        print("Good Morning!")

    elif hour>=12 and hour<18:
        print("Good Afternoon!")   

    else:
        print("Good Evening!")  

    print("I am Jarvis Sir. Please tell me how may I help you")       

# def takeCommand():
#     #It takes microphone input from the user and returns string output

#     r = sr.Recognizer()
#     with sr.Microphone() as source:
#         print("Listening...")
#         r.pause_threshold = 1
#         audio = r.listen(source)

#     try:
#         print("Recognizing...")    
#         query = r.recognize_google(audio, language='en-in')
#         print(f"User said: {query}\n")

#     except Exception as e:
#         # print(e)    
#         print("Say that again please...")  
#         return "None"
#     return query

# def sendEmail(to, content):
#     server = smtplib.SMTP('smtp.gmail.com', 587)
#     server.ehlo()
#     server.starttls()
#     server.login('youremail@gmail.com', 'your-password')
#     server.sendmail('youremail@gmail.com', to, content)
#     server.close()


#wishMe()
# if 1:
query = sys.argv[1]
result = {}


# Logic for executing tasks based on query
# if 'wikipedia' in query:
#     speak('Searching Wikipedia...')
#     query = query.replace("wikipedia", "")
#     results = wikipedia.summary(query, sentences=2)
#     speak("According to Wikipedia")
#     print(results)
#     speak(results)

# elif 'open youtube' in query:
#     webbrowser.open("youtube.com")

# elif 'open google' in query:
#     webbrowser.open("google.com")

# elif 'open stackoverflow' in query:
#     webbrowser.open("stackoverflow.com")   


# elif 'play music' in query:
#     music_dir = 'D:\\Non Critical\\songs\\Favorite Songs2'
#     songs = os.listdir(music_dir)
#     print(songs)    
#     os.startfile(os.path.join(music_dir, songs[0]))

if 'the time' in query:
    strTime = datetime.datetime.now().strftime("%H:%M:%S")    
    #print(f"Sir, the time is {strTime}")
    result['res'] = f"Sir, the time is {strTime}"
    print(json.dumps(result))