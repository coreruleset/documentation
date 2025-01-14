# Release steps

Update install.md file from the hugo repository to:

```sh
sed -e 's/{{< param crs_latest_release >}}/4.0.0/g' \
-e 's/{{< param crs_dev_branch >}}/main/g' \
-e 's:{{< param crs_install_dir >}}:/etc/crs4:g' \
-e 's,{{< ref "1-2-extended_install.md" >}},https://coreruleset.org/docs/deployment/extended_install/,g'
```
