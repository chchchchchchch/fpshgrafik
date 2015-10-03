#!/bin/bash

  SVG=131110_LGRU.svg
  TMPDIR=tmp
  MASTERNAME=`basename $SVG | rev | cut -d "." -f 2- | rev`
  WWWPATH="http://www.forkable.eu/generators/gluemarko"


# --------------------------------------------------------------------------- #
  OUTPUTDIR=o/svg/$MASTERNAME
# if [ -d $OUTPUTDIR ]; then  echo $OUTPUTDIR exists 
#                       else mkdir $OUTPUTDIR
# fi
  PDFDIR=o/pdf/$MASTERNAME
# if [ -d $PDFDIR ]; then  echo $PDFDIR exists 
#                    else mkdir $PDFDIR
# fi
# --------------------------------------------------------------------------- #


  INFOLAYER="i/utils/cornerinfos_A4_texgyreheros.svg"
  METAINFO="i/utils/metainfo.txt"

# --------------------------------------------------------------------------- #
# SEPARATE SVG BODY FOR EASIER PARSING (BUG FOR EMPTY LAYERS SOLVED)
# --------------------------------------------------------------------------- #

      sed 's/ / \n/g' $SVG | \
      sed '/^.$/d' | \
      sed -n '/<\/metadata>/,/<\/svg>/p' | sed '1d;$d' | \
      sed ':a;N;$!ba;s/\n/ /g' | \
      sed 's/<\/g>/\n<\/g>/g' | \
      sed 's/\/>/\n\/>\n/g' | \
      sed 's/\(<g.*inkscape:groupmode="layer"[^"]*"\)/QWERTZUIOP\1/g' | \
      sed ':a;N;$!ba;s/\n/ /g' | \
      sed 's/QWERTZUIOP/\n\n\n\n/g' | \
      sed 's/display:none/display:inline/g' >> ${SVG%%.*}.tmp

  SVGHEADER=`tac $SVG | sed -n '/<\/metadata>/,$p' | tac`

# --------------------------------------------------------------------------- #
# WRITE LIST WITH LAYERS
# --------------------------------------------------------------------------- #

  LAYERLIST=layer.list ; if [ -f $LAYERLIST ]; then rm $LAYERLIST ; fi
  TYPESLIST=types.list ; if [ -f $TYPESLIST ]; then rm $TYPESLIST ; fi

  CNT=1
  for LAYER in `cat ${SVG%%.*}.tmp | \
                sed 's/ /ASDFGHJKL/g' | \
                sed '/^.$/d' | \
                grep -v "label=\"XX_"`
   do
       NAME=`echo $LAYER | \
             sed 's/ASDFGHJKL/ /g' | \
             sed 's/\" /\"\n/g' | \
             grep inkscape:label | grep -v XX | \
             cut -d "\"" -f 2 | sed 's/[[:space:]]\+//g'`
       echo $NAME >> $LAYERLIST
       CNT=`expr $CNT + 1`
  done

  cat $LAYERLIST | sed '/^$/d' | sort | uniq > $TYPESLIST

# --------------------------------------------------------------------------- #
# GENERATE CODE FOR FOR-LOOP TO EVALUATE COMBINATIONS
#---------------------------------------------------------------------------- #

  KOMBILIST=kombinationen.list ; if [ -f $KOMBILIST ]; then rm $KOMBILIST ; fi

  # RESET (IMPORTANT FOR 'FOR'-LOOP)
  LOOPSTART=""
  VARIABLES=""
  LOOPCLOSE=""  

  CNT=0  
  for BASETYPE in `cat $TYPESLIST | cut -d "-" -f 1 | sort | uniq`
   do
      LOOPSTART=${LOOPSTART}"for V$CNT in \`grep $BASETYPE $TYPESLIST \`; do "
      VARIABLES=${VARIABLES}'$'V${CNT}" "
      LOOPCLOSE=${LOOPCLOSE}"done; "

      CNT=`expr $CNT + 1`
  done

# --------------------------------------------------------------------------- #
# EXECUTE CODE FOR FOR-LOOP TO EVALUATE COMBINATIONS
# --------------------------------------------------------------------------- #

 #echo ${LOOPSTART}" echo $VARIABLES >> $KOMBILIST ;"${LOOPCLOSE}
  eval ${LOOPSTART}" echo $VARIABLES >> $KOMBILIST ;"${LOOPCLOSE}

# ------------------------------------------------------------------------------- #
# WRITE SVG FILES ACCORDING TO POSSIBLE COMBINATIONS
# ------------------------------------------------------------------------------- #

  for KOMBI in `cat $KOMBILIST | sed 's/ /DHSZEJDS/g'`
   do
      KOMBI=`echo $KOMBI | sed 's/DHSZEJDS/ /g'`
      NAME=$MASTERNAME
     #OSVG=$OUTPUTDIR/${NAME}_`echo ${KOMBI} | \
     #                         md5sum | cut -c 1-7`.svg
      OSVG=$TMPDIR/${NAME}_`echo ${KOMBI} | \
                            md5sum | cut -c 1-7`

      echo "$SVGHEADER"                                   >  ${OSVG}.svg

       for LAYERNAME in `echo $KOMBI`
        do
          grep -n "label=\"$LAYERNAME\"" ${SVG%%.*}.tmp   >> ${OSVG}.tmp
       done

      cat ${OSVG%%.*}.tmp | sort -n | cut -d ":" -f 2-    >> ${OSVG}.svg
      echo "</svg>"                                       >> ${OSVG}.svg

    # ANGLE=$((RANDOM%720))
    # ANGLE BASED ON MD5SUM  
      ANGLE=`echo $KOMBI | md5sum | tr -d 'a-z' | cut -c 1-4`; #echo $ANGLE
      ROTATION="rotate($ANGLE,210,210)"
      sed -i "s/transform4sh=\"rotate([^\"]*\"/transform=\"$ROTATION\"/g"  \
              ${OSVG}.svg

     #inkscape --vacuum-defs ${OSVG}
      inkscape --export-pdf=${OSVG}.pdf ${OSVG}.svg
      rm ${OSVG%%.*}.tmp
  
  done

  pdftk $TMPDIR/${NAME}*.pdf cat output ../FREEZE/${MASTERNAME}.pdf


# --------------------------------------------------------------------------- #
# REMOVE TEMP FILES
# --------------------------------------------------------------------------- #
  rm ${SVG%%.*}.tmp $KOMBILIST $LAYERLIST $TYPESLIST




  exit 0;





# --------------------------------------------------------------------------- #
# LAYOUT PRINTSHEETS (3x4)
# --------------------------------------------------------------------------- #
  e () { echo $1 >> $OUT ; }
# --------------------------------------------------------------------------- #

  OUT=stickers.tex

  ALL=`ls ${OUTPUTDIR}/*.svg | wc -l`

  PACK=12
  CNT=$PACK

 while [ $CNT -le $ALL ]
  do

  if [ -f $OUT ]; then rm $OUT ;fi

  e "\documentclass{scrbook}"
  e "\pagestyle{empty}"
  e "\usepackage{pdfpages}"
  e "\usepackage{geometry}"
  e "\geometry{paperwidth=210mm,paperheight=297mm}"
  e "\begin{document}"

  e "\includepdfmerge"
  e "[nup=3x4,scale=.55,noautoscale,"
  e " delta=8 18,offset=0 0]"

  for SVG in `ls ${OUTPUTDIR}/*.svg | \
              head -n $CNT | \
              tail -n $PACK`
   do
      PDF=${SVG%%.*}.pdf
      inkscape --export-pdf=${PDF} \
               $SVG
      PDFALL=${PDFALL},${PDF}
  done

  PDFALL=`echo $PDFALL | cut -d "," -f 2-`

  e "{"$PDFALL"}"
  e "\end{document}"

  pdflatex --output-directory=$PDFDIR $OUT > /dev/null

  echo $PDFALL | \
  sed 's/,/\n/g' | \
  sed "s,^,${WWWPATH}/,g" | \
  sed 's/\.pdf$/\.svg/g' > $TMPDIR/svg.list

  PDFALL=`echo $PDFALL | \
          sed 's/,/\n/g' | \
          rev | \
          cut -d "/" -f 1 | \
          rev | \
          cut -d "." -f 1 | \
          sed ':a;N;$!ba;s/\n/ /g'`

  UNIQNAME=${MASTERNAME}_`echo $PDFALL | \
                          md5sum | \
                          cut -c 1-8`.pdf

  mv $TMPDIR/svg.list ${PDFDIR}/${UNIQNAME%%.*}.list
 
# --------------------------------------------------------------------------- #
# AND SOME INFORMATION
# --------------------------------------------------------------------------- #
  TITLE="$MASTERNAME ("`expr $CNT - $PACK + 1`"–${CNT}/$ALL)"
  SUBJECT="Tools Shape Practise Shapes Tools"
  KEYWORDS="generative illustration"
  AUTHOR="LAFKON Publishing"
  PRODUCER="http://freeze.sh/git/generators/gluemarko"/`basename $0`

  INDENT="          "
  DWNLDURL=${WWWPATH}/${PDFDIR}/${UNIQNAME}
  GITEDITION="$PRODUCER ("`expr $CNT - $PACK + 1`"–${CNT}/$ALL)"
  sed "s,BOTTOMRIGHT,$DWNLDURL$INDENT,g" $INFOLAYER | \
  sed "s,BOTTOMLEFT,$INDENT$GITEDITION,g" | \
  sed "s,TOPRIGHT,,g" | \
  sed "s,TOPLEFT,,g"                   > $TMPDIR/info.svg 
  inkscape --export-pdf=$TMPDIR/info.pdf $TMPDIR/info.svg

  pdftk $PDFDIR/${OUT%%.*}.pdf \
        background $TMPDIR/info.pdf \
        output $TMPDIR/$UNIQNAME

  sed "s,TITLE,$TITLE,g" $METAINFO | \
  sed "s,SUBJECT,$SUBJECT,g" | \
  sed "s,KEYWORDS,$KEYWORDS,g" | \
  sed "s,AUTHOR,$AUTHOR,g" | \
  sed "s,PRODUCER,$PRODUCER,g" \
  > $TMPDIR/metainfo.txt

# cat $TMPDIR/metainfo.txt

  pdftk $TMPDIR/$UNIQNAME update_info $TMPDIR/metainfo.txt \
        output $PDFDIR/$UNIQNAME

# --------------------------------------------------------------------------- #

  rm $OUT $PDFDIR/${OUT%%.*}.*
  CNT=`expr $CNT + $PACK`; echo $CNT

 done

 rm $OUTPUTDIR/*.pdf # $TMPDIR/*.svg

exit 0;


