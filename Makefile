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

	kubeseal --format=yaml --cert=.secrets/cert.pem \
		--scope=strict \
		--namespace=$(ns) < .secrets/generated/$(name).json > .secrets/generated/$(name).yaml

	rm .secrets/generated/$(name).json

external-dns:
	@[ "${env}" ] || ( echo "*** env is not set"; exit 1 )
	@[ "${cluster}" ] || ( echo "*** cluster is not set"; exit 1 )

	make seal-file name=external-dns-credentials ns=external-dns file=.secrets/external-dns-credentials.yaml

	mv .secrets/generated/external-dns-credentials.yaml clusters/$(env)/$(cluster)/external-dns-credentials.yaml

grafana-pass:
	kubectl -n monitoring create secret generic grafana-admin-auth \
		--from-literal=admin-user=admin \
		--from-literal=admin-password=$(pass) \
		--dry-run \
		-o json > .secrets/grafana-admin-auth.json

	kubeseal --format=yaml --cert=.secrets/cert.pem < .secrets/grafana-admin-auth.json > .secrets/generated/grafana-admin-auth.yaml
	
	# make seal-file name=grafana-admin-auth ns=monitoring file=.secrets/grafana-admin-auth.yaml

ss-kiali-login:
	@[ "${env}" ] || ( echo "*** env is not set"; exit 1 )
	@[ "${namespace}" ]   || ( echo "*** namespace is not set"; exit 1 )
	@[ "${username}" ] || ( echo "*** username is not set"; exit 1 )
	@[ "${password}" ]   || ( echo "*** password is not set"; exit 1 )
	
	kubectl -n $(namespace) create secret generic kiali \
		--from-literal=username=$(username) \
		--from-literal=passphrase=$(password) \
		--dry-run \
		-o json > kiali.json

	kubeseal --format=yaml --cert=certs/$(env).pem \
		--scope=strict \
		--namespace=$(namespace) < kiali.json > kiali.yaml

	mv kiali.yaml clusters/$(env)
	rm kiali.json

	echo "\n>>> Kiali admin login credentials encrypted succesfully"

demo_msg:
	kubectl -n team2 create secret generic hello-kube-msg \
		--from-literal=msg="secret hello kubernetes" \
		--dry-run \
		-o json > .secrets/generated/msg-secret.json

	kubeseal --format=yaml --cert=.secrets/cert.pem < .secrets/generated/msg-secret.json > .secrets/generated/msg-secret.yaml

istio-manifest:
	@[ "${version}" ] || ( echo "*** version is not set"; exit 1 )

	cd bases/istio; sh generate-manifest.sh $(version)