# Code and Software (all free)
* My AppleScript for [automating overnight recordings with Audition](https://github.com/AndrewW-NFC/Bird-Audio-Resources/blob/main/Audition%201-hour%20recordings%20with%20break%20at%20midnight%20and%20enrivonmental%20conditions.scpt). This code starts and stops Audition recordings every hour, with a special stop at midnight, all in order to follow eBird's NFC protocol. It saves each file using a filename that includes the start date and time. It also logs that hour's weather conditions. I'm still experimenting with how to add accurate local precipitation data to the log.
* My Python script for [generating a local recording quality forecast](https://github.com/AndrewW-NFC/Bird-Audio-Resources/blob/main/NFC%20quality%20weather%20forecast.py).
* [Audacity](https://audacityteam.org) for "viewing", listening to, and editing recordings
* [Vesper](https://github.com/RichardLitt/nfc-resources) and [Nighthawk](https://github.com/bmvandoren/Nighthawk), software specifically for analyzing long NFC recording sessions. Nighthawk can analyze an audio file and generate a spreadsheet of bird sounds it has identified, including the timestamp of the sound and Nighthawk's best guess at the class and species. For Audacity users, Nighthawk can generate a label track -- labeling each sound on the audio track and letting you bulk-export every sound as a separate file.
> [!NOTE]
  > Nighthawk is not designed to analyze bird songs. Its training data are calls.
* [Merlin](https://merlin.allaboutbirds.org/): the go-to bird sound ID app, but it is not suitable for NFCs.
* BirdNET Analyzer
* [BirdNET API](https://birdnet.cornell.edu/api/): web-based bird sound ID. Unless you're using the API for other projects, consider this merely a backup option for Merlin, as its matches aren't filtered by date and location. It is not suitable for NFCs.

> [!NOTE]
> Merlin and BirdNET aren't well-trained on flight calls that differ from "terrestial" calls. Though you might get lucky, assume those platforms will not make reliable (or any) flight call IDs.
