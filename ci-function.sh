#!/bin/bash

function GetTag(){
    if [[ $CI_COMMIT_REF_NAME == "develop" ]];then
	echo d${CI_PIPELINE_ID}_${CI_COMMIT_SHORT_SHA}
    elif [[ $CI_COMMIT_REF_NAME == "staging" ]];then
	echo s${CI_PIPELINE_ID}_${CI_COMMIT_SHORT_SHA}
    elif [[ $CI_COMMIT_REF_NAME == "master" ]];then
	echo p${CI_PIPELINE_ID}_${CI_COMMIT_SHORT_SHA}
    fi
}

function GetValuesFile(){
    if [[ $CI_COMMIT_REF_NAME == "develop" ]];then
	echo "values_dev.yaml"
    elif [[ $CI_COMMIT_REF_NAME == "staging" ]];then
	echo "values_stg.yaml"
    elif [[ $CI_COMMIT_REF_NAME == "master" ]];then
	echo "values_prod.yaml"
    fi
}

function GetPrefixApplication(){
    local TMPDIR=$(mktemp -u -d)
    local PREFIX=""
    git clone -b master --depth=1 $GITOPS_URL $TMPDIR
    if find $TMPDIR/frontend -type d -name "$IMAGE" | grep "$IMAGE" 2>&1 >/dev/null;then
	PREFIX="frontend"
    else
	PREFIX="backend"
    fi
    rm -rf $TMPDIR
    echo $PREFIX
}

function Build(){
    local IMAGE_TAG
    if [[ -n $1 ]];then
	IMAGE_TAG=$1
    else
	IMAGE_TAG=$TAG
    fi
    docker build -t $IMAGE:$IMAGE_TAG .
    docker tag $IMAGE:$IMAGE_TAG $REGISTRY/$HUB_NAMESPACE/$IMAGE:$IMAGE_TAG
    docker push $REGISTRY/$HUB_NAMESPACE/$IMAGE:$IMAGE_TAG
}

function Deploy(){
    local IMAGE_TAG
    local TMPDIR=$(mktemp -u -d)
    if [[ -n $1 ]];then
	IMAGE_TAG=$1
    else
	IMAGE_TAG=$TAG
    fi
    git clone -b master --depth=1 $GITOPS_URL $TMPDIR
    bash $TMPDIR/script/update-tag.sh -a $APPLICATION -f $VALUES_FILE -t $IMAGE_TAG
    rm -rf $TMPDIR

}
