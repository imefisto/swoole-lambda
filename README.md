# Swoole lambda

This post is inspired on [Using Bref's LambdaRuntime to Asynchronously Run Swoole Coroutines as Functions on AWS](https://dev.to/leocavalcante/using-brefs-lambaruntime-to-asynchronously-run-swoole-coroutines-as-functions-on-aws-1icm).

## Steps to provision your lambda

Generate the vendors folder:

```
composer install
```

Create the zips with the lambda layers:

```
zip -r ./runtime.zip bootstrap bin cacert.pem
zip -r ./vendor.zip vendor
```

Then apply the terraform.
