sealed_secrets_local_cert:
	kubeseal --fetch-cert \
		--controller-namespace=kube-system \
		--controller-name=sealed-secrets \
	> pub-cert.pem

seal-file:
	mkdir -p .secrets/generated

	kubectl create secret generic $(name) -n $(ns) \
	--from-file=$(file) \
	--dry-run \
	-o json > .secrets/generated/$(name).json

	kubeseal --format=yaml --cert=.secrets/cert.pem < .secrets/generated/$(name).json > .secrets/generated/$(name).yaml

	rm .secrets/generated/$(name).json

external-dns:
	make seal-file name=svc-lb-public ns=external-dns file=.secrets/svc-lb-public.yaml
	make seal-file name=svc-lb-internal ns=external-dns file=.secrets/svc-lb-internal.yaml

grafana-pass:
	kubectl -n monitoring create secret generic grafana-admin-auth \
		--from-literal=admin-user=admin \
		--from-literal=admin-password=$(pass) \
		--dry-run \
		-o json > .secrets/grafana-admin-auth.json

	kubeseal --format=yaml --cert=.secrets/cert.pem < .secrets/grafana-admin-auth.json > .secrets/generated/grafana-admin-auth.yaml
	
	# make seal-file name=grafana-admin-auth ns=monitoring file=.secrets/grafana-admin-auth.yaml

demo_msg:
	kubectl -n team2 create secret generic hello-kube-msg \
		--from-literal=msg="secret hello kubernetes" \
		--dry-run \
		-o json > .secrets/generated/msg-secret.json

	kubeseal --format=yaml --cert=.secrets/cert.pem < .secrets/generated/msg-secret.json > .secrets/generated/msg-secret.yaml