pkgname=omni-cli
pkgver=1.0.0
pkgrel=1
pkgdesc="TUI project manager for tmux"
arch=('any')
url="https://github.com/nickojs/omni-cli"
license=('MIT')
depends=('tmux' 'jq' 'age' 'gocryptfs' 'fuse2' 'util-linux')
source=("git+${url}.git")
sha256sums=('SKIP')

package() {
    cd "$srcdir/$pkgname"

    # Install app modules and scripts to /usr/lib/omni-cli
    install -dm755 "${pkgdir}/usr/lib/omni-cli"
    cp -r modules styles "${pkgdir}/usr/lib/omni-cli/"
    install -Dm755 startup.sh "${pkgdir}/usr/lib/omni-cli/startup.sh"
    install -Dm644 .env "${pkgdir}/usr/lib/omni-cli/.env"

    # Wrapper that delegates to the main entrypoint
    install -dm755 "${pkgdir}/usr/bin"
    cat > "${pkgdir}/usr/bin/omni-cli" <<'EOF'
#!/usr/bin/env bash
exec /usr/lib/omni-cli/startup.sh "$@"
EOF
    chmod 755 "${pkgdir}/usr/bin/omni-cli"

    # License
    install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
