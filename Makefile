sealed_secrets_local_cert:
	kubeseal --fetch-cert \
		--controller-namespace=kube-system \
		--controller-name=sealed-secrets \
	> pub-cert.pem

seal-file:
	@[ "${file}" ] || ( echo "*** file is not set"; exit 1 )
	@[ "${name}" ] || ( echo "*** name is not set"; exit 1 )
	@[ "${ns}" ] || ( echo "*** ns is not set"; exit 1 )

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
	@[ "${env}" ] || ( echo "*** env is not set"; exit 1 )
	@[ "${cluster}" ] || ( echo "*** cluster is not set"; exit 1 )
	@[ "${namespace}" ] || ( echo "*** namespace is not set"; exit 1 )
	@[ "${pass}" ] || ( echo "*** namespace is not set"; exit 1 )

	kubectl -n monitoring create secret generic grafana-admin-credentials \
		--from-literal=admin-user=admin \
		--from-literal=admin-password=$(pass) \
		--dry-run \
		-o json > .secrets/grafana-admin-credentials.json

	kubeseal --format=yaml --cert=.secrets/cert.pem \
		--scope=strict \
		--namespace=$(namespace) < .secrets/grafana-admin-credentials.json > .secrets/generated/grafana-admin-credentials.yaml
	
	mv .secrets/generated/grafana-admin-credentials.yaml clusters/$(env)/$(cluster)/grafana-admin-credentials.yaml
	# make seal-file name=grafana-admin-auth ns=monitoring file=.secrets/grafana-admin-auth.yaml

ss-kiali-login:
	@[ "${env}" ] || ( echo "*** env is not set"; exit 1 )
	@[ "${cluster}" ] || ( echo "*** cluster is not set"; exit 1 )
	@[ "${namespace}" ]   || ( echo "*** namespace is not set"; exit 1 )
	@[ "${username}" ] || ( echo "*** username is not set"; exit 1 )
	@[ "${password}" ]   || ( echo "*** password is not set"; exit 1 )
	
	kubectl -n $(namespace) create secret generic kiali \
		--from-literal=username=$(username) \
		--from-literal=passphrase=$(password) \
		--dry-run \
		-o json > kiali.json

	kubeseal --format=yaml --cert=.secrets/cert.pem \
		--scope=strict \
		--namespace=$(namespace) < kiali.json > kiali.yaml

	mv kiali.yaml clusters/$(env)/$(cluster)
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

encrypt-all:
	make external-dns env=lab cluster=main
	make grafana-pass env=lab cluster=main namespace=monitoring pass=P@ssw0rd
	# make ss-kiali-login env=lab cluster=main namespace=monitoring username=admin password=admin

check: 
	sh kustomize-check.sh


descrypt:
	@[ "${key}" ] || ( echo "*** key is not set"; exit 1 )
	@[ "${file}" ] || ( echo "*** file is not set"; exit 1 )

	kubeseal --recovery-unseal --recovery-private-key $(key) -o yaml < $(file)