### 查看时长
```ffprobe -i .\Media\Sounds\10.ogg -show_entries format=duration -v quiet -of csv="p=0"```
### 截取音频
```ffmpeg.exe -i audio1.mp3 -ss 00:00:00 -t 00:05:00 audio截取版1.mp3```

ffmpeg -i 'C:\Users\p.wang\Downloads\audio.wav' -ss 00:00:00 -t 00:00:01 tmp/3.ogg ; rm 'C:\Users\p.wang\Downloads\audio.wav'

rm 'C:\Users\p.wang\Downloads\audio.wav'

mv .\tmp\8.ogg .\Media\Sounds\ -Force


### 音量
```ffmpeg -i .\Media\Sounds\5.ogg -filter:a volumedetect -f null /dev/null```


### 换音量
```ffmpeg -i .\Media\Sounds\5.ogg -af "volume=14dB" .\tmp\5.ogg```

ffmpeg -i .\Media\Sounds\5.ogg -filter:a volumedetect -f null /dev/null

ffmpeg -i .\Media\Sounds\5.ogg -af "volume=14dB" .\tmp\5.ogg

ffmpeg -i .\tmp\4.ogg -filter:a volumedetect -f null /dev/null