#Microsoft Teams clone which I made for Microsoft Engage 2021 mentorship program.

DEMO LINK: https://youtu.be/GxoqLromQJY

FRONT-END: The front end is a cross platform application made in Flutter, however only android is completely supported right now.

BACKEND: The backend is made using Node.js, ExpressJS, MongoDB, mongoose, and it is hosted on heroku whereas the database is hosted on mongodb atlas.

AUTHENTICATION: I've added email and password authentication using google firebase. Users can register, sign-in and logout.

CHAT: I've used socket.io to implement chat. I've also added support for media and location messages. Images are being stored in mongodb whereas files are being stored in firebase storage. Images are being cached in the application to reduce data usage.

VIDEO MEET: I've achieved the minimum functionality by using jitsi meet for video calling where I can group video call, share screen, raise hand and much more. While jitsi meet comes with a chat feature in video calls, it cannot be accessed before and after the meeting, so I've connected chat rooms with video calls so that chat can be started before the meeting and can remain forever, thereby completing the surprise feature.

CALENDAR: I've also added a synchronised calendar where users can create events either for themselves or for their teams.

SEARCH: A search feature is also added which can search for chat rooms, chat messages (text messages and file messages' names only) and events. A search is performed by making a regular expression from the user's query and then using mongodb's find function.

CENSORSHIP: An additional feature which cleans english profanity in messages and prevents images containing explicit content to be sent in chat rooms where censorship is enabled. Images are filtered using deepai's nsfw detector api.
