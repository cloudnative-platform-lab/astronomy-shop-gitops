# Dev checkout dependencies

Checkout requires two internal gRPC services that were previously absent from the
Dev delivery path:

- `shipping:50051` implements quote and shipment calls.
- `email:8080` implements the `EmailService.SendOrderConfirmation` gRPC call.

The image values files intentionally start with empty `tag` and `digest` fields.
Do not activate their ApplicationSet until the two CI workflows have populated
those immutable values.

## Activation order

1. Apply the shared Terraform change that creates the `astronomy-shop/email`
   and `astronomy-shop/shipping` ECR repositories.
2. Push the application-repository changes, then run the **Build Missing Dev
   Service Image** workflow once for `shipping` and once for `email`.
3. Confirm both `helm-values/dev/*-values.yaml` files contain a non-empty tag
   and digest committed by CI.
4. Rename
   `argocd/appsets/dev/services-with-checkout-dependencies.yaml.disabled` to
   `services-with-checkout-dependencies.yaml`, commit, and push.
5. Argo CD automatically creates `shipping-dev` and `email-dev`; wait for both
   Rollouts to become healthy before testing checkout.

Keeping the ApplicationSet disabled before step 3 is deliberate: it prevents
Argo CD from rendering and deploying an image reference that does not exist.
