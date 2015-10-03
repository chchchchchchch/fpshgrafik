#!/bin/bash

 TARGET=150526_fontain.svg


 LAYERNAME=`date +%Y%m%d-%H%M%S`
 ID=`echo $LAYERNAME | md5sum | cut -c 1-5`

 sed -i 's,</svg>,,g' $TARGET
 echo "<g style=\"display:inline\"  \
        id=\"${ID}01\"               \
        inkscape:groupmode=\"layer\"  \
        inkscape:label=\"$LAYERNAME\">"| #
 tr -s ' '                                 >> $TARGET

 fc-list > /tmp/fc.list

 XSHIFT="40";YSHIFT="70"
 X1="15";Y1="20"
 XPOS="$X1";YPOS="$Y1"



 COUNT=0
 while [ $COUNT -lt 120 ]
  do
     SELECTFONT=`cat /tmp/fc.list | #
                 shuf -n 1        | #
                 sed 's/\\\-/-/g'`  #
     FONTFAMILY=`echo $SELECTFONT | #
                 cut -d ":" -f 2  | #
                 cut -d "," -f 1  | #
                 sed 's/^[ \t]*//g'`
       FONTSPEC=`echo $SELECTFONT | #
                 cut -d ":" -f 2  | #
                 cut -d "," -f 2  | #
                 sed 's/^[ \t]*//g'`
    LETTER="R"
    DESCRIPTION="lfkn.de/fr53"
    DESCRIPTION="$FONTFAMILY"
   
    LETTERSTYLE=`echo "font-size:80px;       \
                       text-align:center;     \
                       writing-mode:lr-tb;     \
                       text-anchor:middle;      \
                       fill:#000000;             \
                       font-family:'$FONTFAMILY'; \
                       -inkscape-font-specification:'$FONTSPEC'" | #
                  sed 's/;[ \t]*/;/g'`
   
    DESCRIPTIONSTYLE=`echo "font-size:8px;         \
                            text-align:center;      \
                            line-height:100%;        \
                            writing-mode:lr-tb;       \
                            text-anchor:middle;        \
                            fill:#000000;               \
                            font-family:Source Code Pro; \
                           -inkscape-font-specification:Source Code Pro Medium" | #
                      sed 's/;[ \t]*/;/g'`

    ID=`echo $RANDOM | md5sum | cut -c 1-3`   

    echo "<g transform=\"translate($XPOS,$YPOS) scale(0.5)\" \
           id=\"${ID}02\">" | #
    tr -s ' '   >> $TARGET

    echo "<flowRoot xml:space=\"preserve\" id=\"${ID}03\"           \
           style=\"$LETTERSTYLE\"><flowRegion id=\"${ID}03\">        \
          <rect id=\"${ID}04\" width=\"100\" height=\"100\" x=\"0\" y=\"0\"\
           style=\"$LETTERSTYLE\" /></flowRegion>                      \
          <flowPara id=\"${ID}05\">$LETTER</flowPara></flowRoot>        \
          <path style=\"fill:none;\" d=\"m 10,94 80,0 0,40 -80,0 z\"     \
           id=\"${ID}06\" inkscape:connector-curvature=\"0\" />           \
          <flowRoot xml:space=\"preserve\" id=\"${ID}07\"                  \
           style=\"$DESCRIPTIONSTYLE\"><flowRegion id=\"${ID}08\">          \
          <rect id=\"${ID}09\" width=\"76\" height=\"45\" x=\"12\" y=\"99\"  \
           style=\"$DESCRIPTIONSTYLE\" /></flowRegion><flowPara               \
           id=\"${ID}10\">$DESCRIPTION</flowPara></flowRoot>" | #
     tr -s ' ' | sed 's/>[ \t]*</></g'     >> $TARGET
     echo "</g>"                           >> $TARGET

     XPOS=`expr $XPOS + $XSHIFT`
     COUNT=`expr $COUNT + 1`
     ROW=`expr $ROW + 1`  
     if [ $ROW -eq 12 ]; then
          XPOS=$X1
          YPOS=`expr $YPOS + $YSHIFT`
           ROW="0"
     fi
  done

  echo "</g>"                              >> $TARGET
  echo "</svg>"                            >> $TARGET
  
exit 0;
