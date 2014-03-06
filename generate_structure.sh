#run this file to generate the structure.md file. It works by extracting the second line of each README file in the site structure - excludes the node_modules folder.

find . -type d -and -not -path '*node_modules*' > structure #Generates the structure

#OPTION 1: This for outputting just the directories with readmes
rm structure.md
cat structure | while read line
do
	if [ -f ${line}/README.md ]; then
		sed -n '2p' ${line}/README.md | sed 's/^/ :	/' | awk -v readmepath=$line '{print readmepath""$0}' >> structure.md
	fi
done

rm structure
#END OPTION 1

#OPTION 2: this for outputting all directories and appending the readme line where it exists
#cat structure | while read line
#do
#	if [ -f ${line}/README.md ]; then
#		sed -n '2p' ${line}/README.md | sed 's/^/	/' >> structure-readmes
#	else
#		echo '' >> structure-readmes
#	fi
#done
#
#paste -d ' :' structure structure-readmes > structure.md
#
#rm structure
#rm structure-readmes
#END OPTION 2