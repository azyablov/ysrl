#!/bin/bash
ROOT=`pwd`
PREFIX=`pwd`/srlinux-yang-models/srlinux-yang-models
if [ -d srlinux-yang-models ]; then
    cd srlinux-yang-models
else
    exit 1
fi
TAGS=`git tag`
for TAG in $TAGS; do 
    echo ">>> Generating code for $TAG <<<";
    git checkout $TAG
    mkdir -p ../srl/${TAG}
    # Renaming tools
    find ./srlinux-yang-models -name srl_nokia-tools* -exec rename srl_nokia-tools __srl_nokia-tools '{}' \;
    # Generate code
    generator -path ${PREFIX} \
    -logtostderr \
    -output_file=../srl/${TAG}/ysrl.go -package_name=ysrl \
    -generate_fakeroot -fakeroot_name=Device \
    -compress_paths=false \
    -shorten_enum_leaf_names \
    -typedef_enum_with_defmod \
    -enum_suffix_for_simple_union_enums \
    -generate_rename \
    -generate_append \
    -generate_getters \
    -generate_delete \
    -generate_simple_unions \
    -generate_populate_defaults \
    -include_schema \
    -exclude_state \
    -yangpresence \
    -include_model_data \
    ${PREFIX}/srl_nokia/models/*/srl_nokia*.yang
    if [ $? != 0 ]; then 
        echo "FAILED to generate code for $TAG";
        rm -rf ../srl/${TAG};
    else
        cd ../srl/${TAG};
        rm -f go*;
        go mod init;
        go mod tidy;
        cd $ROOT/srlinux-yang-models
        go work use ../srl/${TAG};
    fi
    # Restoring tools back
    find ./srlinux-yang-models -name __srl_nokia-tools* -exec rename __srl_nokia-tools srl_nokia-tools '{}' \;
done
