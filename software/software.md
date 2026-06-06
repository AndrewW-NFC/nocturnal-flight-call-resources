# Applications
* [Audacity](https://audacityteam.org) for "viewing", listening to, and editing recordings
* [Nighthawk](https://github.com/bmvandoren/Nighthawk) and [Vesper](https://github.com/RichardLitt/nfc-resources), software specifically for analyzing long NFC recording sessions. Nighthawk can analyze an audio file and generate a spreadsheet of bird sounds it has identified, including the timestamp of the sound and Nighthawk's best guess at the class and species. For Audacity users, Nighthawk can generate a label track -- labeling each sound on the audio track and letting you bulk-export every sound as a separate file.
> [!NOTE]
  > Nighthawk is not designed to analyze bird songs. Its training data are calls.
* [Merlin](https://merlin.allaboutbirds.org/). Though it is not trained on NFCs, it can be good for identifying thrushes and some flight songs.
* [BirdNET Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer/). Not deeply trained on NFCs but valuable for its bulk analysis of large files.

# Scripts in this repo
* **Automating overnight recordings with Audition and analyzing recordings in the morning.** To help follow the eBird NFC protocol, this script starts and stops Audition recordings every hour, with a special stop at midnight and a final stop at 6:15am. It saves each file to the desktop using a filename that includes the start date and time. It logs that hour's weather conditions. After 6:15am, it analyzes the files with Nighthawk and BirdNET.
* **Generating a local acoustics quality forecast.**
