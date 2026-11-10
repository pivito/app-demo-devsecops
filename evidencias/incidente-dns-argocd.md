# Recuperación DNS de Argo CD — 10/11/2026

## Diagnóstico confirmado

Contexto: `kind-devsecops`, Ubuntu WSL2. El Repo Server original no resolvía GitHub y el application-controller no resolvía `argocd-repo-server`. BusyBox en el mismo worker sí resolvía usando `10.96.0.10`; también resolvía consultando directamente ambos endpoints CoreDNS.

Los resolv.conf coincidían. Rutas, interfaces y vecinos ARP correspondían a los pods activos. Las NetworkPolicy de Repo Server y application-controller eran únicamente de entrada, sin restricción de salida DNS.

La diferencia determinante era la selección por NetworkPolicy: nftables, tabla `inet kindnet-network-policies`, incluía las IP afectadas en `podips-v4` y enviaba sus consultas DNS a NFQUEUE 101. BusyBox no estaba en ese conjunto. La cola tenía 712 paquetes pendientes en worker y 301 en worker2; los agentes seguían Running. Este mecanismo de kindnet está documentado en su [código oficial](https://github.com/kubernetes-sigs/kind/blob/main/images/kindnetd/cmd/kindnetd/main.go).

La causa operativa fue un atasco del procesamiento NFQUEUE de kindnet, no la antigüedad de los pods por sí misma. Ambos agentes consumían su límite de 100m CPU; no se ha probado qué desencadenó el atasco ni que ese límite fuera su causa. No se atribuye a un bug concreto o a WSL sin más evidencia.

## Corrección controlada

Se guardaron las instantáneas adjuntas y se recreó únicamente el pod kindnet del worker. Se comprobó la recuperación antes de hacer lo mismo con worker2. No se alteraron CoreDNS, NetworkPolicy, límites del DaemonSet ni los pods de Repo Server. Las colas posteriores quedaron en cero y las políticas se reconstruyeron.

El Repo Server original recuperó DNS y `git ls-remote` contra GitHub. Application-controller y argocd-server recuperaron la resolución del servicio Repo Server. No fue necesario modificar Git ni aplicar manifiestos directamente a DEV.

## GitOps DEV

Se solicitó un hard refresh únicamente de `app-demo-dev`. Su automatismo existente ejecutó una sincronización satisfactoria de `k8s/overlays/dev`, rama `feature/gitops-kustomize`, repositorio `https://github.com/pivito/app-demo-devsecops.git`.

- Revisión remota y sincronizada: `9d81843986fabf3d179269bc7811deb5162d7467`.
- Operación: `Succeeded`, `initiatedBy.automated=true`.
- Estado: `Synced`, `Healthy`; rollout terminado y nuevo pod 1/1 Running.
- Imagen aplicada: `sha256:d3334fda944a0966322a4999b20ab081328edac579120e048650c88122ff8472`.

## Protección de STG

Las instantáneas anterior y posterior muestran mismos UID y spec de Deployment, Service, HPA y los dos pods de STG. La spec de su Application y su última operación de sincronización tampoco cambiaron. No se solicitó sync ni refresh de STG. Su imagen sigue siendo `sha256:d3d024be23756030986b466c89599c6584ee74cde99269a7bbfbb0b475d73e81`.

## Si se repite

Inspeccionar `/proc/net/netfilter/nfnetlink_queue` dentro de cada worker y capturar logs/consumo de kindnet antes de reiniciarlo. Una cola sostenida con consultas que expiran requiere investigar el consumidor de políticas. La recuperación aplicada conserva la configuración declarativa; no garantiza que el atasco no reaparezca. Una actualización de kind/kindnet o un ajuste de recursos debe evaluarse por separado con evidencia de recurrencia.
