#!/bin/bash
ROOT=`pwd`
# rm -rf ./srlinux-yang-models
# git clone https://github.com/nokia/srlinux-yang-models
PREFIX=${ROOT}/srlinux-yang-models/srlinux-yang-models
if [ $? == 0 ] && [ -d srlinux-yang-models ] ; then
    cd srlinux-yang-models
else
    exit 1
fi
TAGS=`git tag`
for TAG in $TAGS; do 
    echo ">>> Generating code for $TAG <<<";
    git checkout $TAG
    PKG=`echo ${TAG} | sed -e 's/v\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)/srlv\1m\2p\3/I'`
    mkdir -p ../srl/${PKG}
    # Renaming tools
    find ./srlinux-yang-models -name srl_nokia-tools* -exec rename srl_nokia-tools __srl_nokia-tools '{}' \;
    # Package name
    # Generate code
    generator -path ${PREFIX} \
    -logtostderr \
    -output_file=../srl/${PKG}/ysrl.go -package_name=${PKG} \
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
        rm -rf ../srl/${PKG};
    else
        cd ../srl/${PKG};
        rm -f go*;
        go mod init;
        go mod tidy;
        cd $ROOT/srlinux-yang-models
        # go work use ../srl/${TAG};
    fi
    # Restoring tools back
    find ./srlinux-yang-models -name __srl_nokia-tools* -exec rename __srl_nokia-tools srl_nokia-tools '{}' \;
done
