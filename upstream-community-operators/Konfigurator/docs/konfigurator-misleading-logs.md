# Misleading Logs in case of running Konfigurator globally

If you deploy Konfigurator globally i.e. send `WATCH_NAMESPACE=""`, Konfigurator will be working fine but it will log an error in the start `level=error msg="Failed to initialize service object for operator metrics: WATCH_NAMESPACE must not be empty"`. 

This is a known issue as we are using operator-sdk and use its methods, so the operator-sdk logs this error even though Konfigurator is working fine. We have created an issue in operator-sdk, and will update it accordingly. 

We can overcome this by removing `sdk.ExposeMetricsPort()` from main.go, but it will result us in losing prometheus metrics for our operator.