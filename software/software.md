# Applications
* [Audacity](https://audacityteam.org) for "viewing", listening to, and editing recordings
* [Nighthawk](https://github.com/bmvandoren/Nighthawk) and [Vesper](https://github.com/RichardLitt/nfc-resources), software specifically for analyzing long NFC recording sessions. Nighthawk can analyze an audio file and generate a spreadsheet of bird sounds it has identified, including the timestamp of the sound and Nighthawk's best guess at the class and species. For Audacity users, Nighthawk can generate a label track -- labeling each sound on the audio track and letting you bulk-export every sound as a separate file.
> [!NOTE]
  > Nighthawk is not designed to analyze bird songs. Its training data are calls.
* [Merlin](https://merlin.allaboutbirds.org/). Though it is not trained on NFCs, it can be good for identifying thrushes and some flight songs.
* [BirdNET Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer/). Not deeply trained on NFCs but is valuable for its bulk analysis of large files.

# Scripts
* My AppleScript for [automating overnight recordings with Audition](https://github.com/AndrewW-NFC/nocturnal-flight-call-resources/blob/main/Audition%201-hour%20recordings%20with%20break%20at%20midnight%20and%20enrivonmental%20conditions.scpt). To help follow the eBird NFC protocol, this script starts and stops Audition recordings every hour, with a special stop at midnight. It saves each file using a filename that includes the start date and time. It also logs that hour's weather conditions.
* My scripts for generating a local recording quality forecast. [Python](https://github.com/AndrewW-NFC/Bird-Audio-Resources/blob/main/NFC%20quality%20weather%20forecast.py) | [HTML](https://github.com/AndrewW-NFC/nocturnal-flight-call-resources/blob/main/software/NFC%20acoustics%20quality%20forecast%20)
