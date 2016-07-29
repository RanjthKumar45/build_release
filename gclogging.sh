#!/bin/bash

acceptance_testing=""

function heading(){
message=$1
echo " "
echo "======================================================================"
echo " ${message}"
echo "======================================================================"
echo " "

}

function msg(){
message=$1
echo " "
echo " ${message}"
echo " "
}

function msg(){
message=$1
echo " "
echo "[${message}]"
echo " "
}

function check_syntax_errors(){	
heading "[Starting] check syntax errors using puppet parser"

	check_syntax_errors=`echo puppet parser validate $WORKSPACE/project/manifests/*.pp`
	$check_syntax_errors>$WORKSPACE/log/check_syntax_errors.txt
	cat $WORKSPACE/log/check_syntax_errors.txt

}


function check_code_quality(){
heading "[Starting] code quality check using puppet-lint tool"

	check_code_quality=`echo puppet-lint $WORKSPACE/project`
	$check_code_quality>$WORKSPACE/log/check_code_quality.txt
	cat $WORKSPACE/log/check_code_quality.txt
}


function check_metadata_quality(){
heading "[Starting] Metadata quality check using metadata-json-lint tool"

	check_metadata_quality=`echo metadata-json-lint $WORKSPACE/project/metadata.json`
	$check_metadata_quality>$WORKSPACE/log/check_metadata_quality.txt
	cat $WORKSPACE/log/check_metadata_quality.txt	
}


function acceptance_testing(){
heading "[Starting] Acceptance Testing using Beaker-rspec"
	pushd $WORKSPACE/project	
		sed --in-place '/log_level: verbose/d' "$WORKSPACE/project/spec/acceptance/nodesets/"*.yml
		for entry in "$WORKSPACE/project/spec/acceptance/nodesets"/*
		do
		  node_file=$(basename $entry)
		  filename="${node_file%.*}"
		  msg "OS: $filename"  	
		  result=`echo sudo BEAKER_set="${filename}" bundle exec rspec spec/acceptance`
		  $result>$WORKSPACE/log/acceptance/${filename}.txt
		  cat $WORKSPACE/log/acceptance/${filename}.txt
		done
	popd
}


function unit_testing_resource_coverage(){

heading "[Starting] Unit Testing and Code Coverage Using rspec-puppet tool"
	pushd $WORKSPACE/project
		unit_testing_resource_coverage=`echo rspec --format documentation $WORKSPACE/project/spec/unit/`
		$unit_testing_resource_coverage>$WORKSPACE/log/unit_testing_resource_coverage.txt
		cat $WORKSPACE/log/unit_testing_resource_coverage.txt

		#This for just report purpose	
	#	resouce_coverage=`echo rspec $WORKSPACE/project/spec/unit/*_spec.rb`
		#$resouce_coverage>$WORKSPACE/log/resouce_coverage.txt
	popd
}


function result(){
heading "Result"

msg "1. Syntax errors : "
	
	if [ ! -s $WORKSPACE/log/check_syntax_errors.txt ]; then
		echo "No syntax errors"
		PUPPET_COMPATIBILTY_CHEK_MAIL="<span class='success'>No syntax errors</span>"
	else
		cat $WORKSPACE/log/check_syntax_errors.txt
		value=$(<$WORKSPACE/log/check_syntax_errors.txt)
		PUPPET_COMPATIBILTY_CHEK_MAIL="<span class='error'>${value}</span>"
		
	fi


msg "2. Check code quality : "
	
		
	if [ ! -s $WORKSPACE/log/check_code_quality.txt ]; then
		echo "No errors"
		PUPPET_CODE_QUALITY_CHEK_MAIL="<span class='success'>No errors</span>"
	else
		cat $WORKSPACE/log/check_code_quality.txt
		value=$(<$WORKSPACE/log/check_code_quality.txt)
		PUPPET_CODE_QUALITY_CHEK_MAIL="<span class='error'>${value}</span>"
	fi


msg "3. Check metadata quality : "

	
	if [ ! -s $WORKSPACE/log/check_metadata_quality.txt ]; then
		echo "No errors"
		PUPPET_META_DATA_CHEK_MAIL="<span class='success'>No errors</span>"
	else
		cat $WORKSPACE/log/check_metadata_quality.txt
		value=$(<$WORKSPACE/log/check_metadata_quality.txt)
		PUPPET_META_DATA_CHEK_MAIL="<span class='error'>${value}</span>"
	fi

msg "4. Unit Testing"
	
	unit_testing=`grep --text -P '^[0-9]+ examples, [0-9]+ failures' $WORKSPACE/log/unit_testing_resource_coverage.txt`
	echo $unit_testing
	PUPPET_UNIT_TEST_TIME_TAKEN=`grep -oP '\Finished in\K[^\(f]+' $WORKSPACE/log/unit_testing_resource_coverage.txt`
	
	if [[ "$unit_testing" =~ "^[0-9]+ examples, 0 failures" ]]; then
    		PUPPET_UNIT_TEST_RESULT_MAIL="<span class='error'>${unit_testing}</span>"
	else
    		PUPPET_UNIT_TEST_RESULT_MAIL="<span class='success'>${unit_testing}</span>"
	fi

msg "5. Resource Coverage"

	value=$(grep -oP '\(\K[^\)]+' $WORKSPACE/log/unit_testing_resource_coverage.txt | tail -1)
	PUPPET_RESOURCE_COVERAGE_MAIL=${value}
	echo $value

msg "6. Acceptance testing : "
	PUPPET_ACCEPTANCE_TESTING_MAIL=""
	for entry in "$WORKSPACE/project/spec/acceptance/nodesets"/*
	do
	  node_file=$(basename $entry)
	  filename="${node_file%.*}"
	  final_result=`grep --text -P '^[0-9]+ examples, [0-9]+ failures' $WORKSPACE/log/acceptance/${filename}.txt`
	  echo "${filename}---------------${final_result}"
	  time_taken=`grep -oP '\Finished in\K[^\(f]+' $WORKSPACE/log/acceptance/${filename}.txt`
	  if [[ "$final_result" =~ "^[0-9]+ examples, 0 failures" ]]; then
    		PUPPET_ACCEPTANCE_TESTING_MAIL="${PUPPET_ACCEPTANCE_TESTING_MAIL}<tr><td>${filename}</td><td><span class='error'>${final_result}</span></td><td>${time_taken}</td></tr>"
	  else
    		PUPPET_ACCEPTANCE_TESTING_MAIL="${PUPPET_ACCEPTANCE_TESTING_MAIL}<tr><td>${filename}</td><td><span class='success'>${final_result}</span></td><td>${time_taken}</td></tr>"
	  fi	  
	
	done
}

function init(){

mkdir $WORKSPACE/log
mkdir $WORKSPACE/log/acceptance
mkdir $WORKSPACE/report

#MAIL_JOB_URL="http://104.197.114.129/:8080/job/$JOB_NAME/$BUILD_NUMBER/console"
#MAIL_JOB_NAME=$JOB_NAME

pushd $WORKSPACE/project
	sudo bundle install 
popd 

}

init
check_syntax_errors
check_code_quality
check_metadata_quality
unit_testing_resource_coverage
acceptance_testing
result

pushd $WORKSPACE/scripts
	eval "echo \"$(< puppet_report.html)\"" > $WORKSPACE/report/puppet_report.html
popd





