# Making a release

1. Update bundle version

    - Remove `-dev` suffix from “marketing version”, making it the version you want to release (e.g, 2.0)
    - Do this for both **JustMonika** and **JustMonikaGL** targets

2. Build release binaries

    - Select **JustMonika** target
    - Run _Product_ | _Archive_
    - Rename the resulting archive to “JustMonika v2.0”

3. Notarize the binaries

    - Archive Organizer: _Distribute Content_, _Built Products_
    - Dig out `JustMonika.saver` from that output
    - Check that it's okay for notarization
      - `codesign -vvv --deep --strict JustMonika.saver`
        - `JustMonika.saver: valid on disk`
      - `codesign -dvv JustMonika.saver`
        - `Authority=Developer ID Application: ...`
        - `Timestamp=01 Jan 2020, 00:00:00`
    - Submit it in a ZIP archive for notarization
      - `zip --symlink -r JustMonika.saver.zip JustMonika.saver`
      - ```
        xcrun altool --notarize-app \
                     --primary-bundle-id "net.ilammy.JustMonika" \
                     --username "me@ilammy.net" \
                     --password "@keychain:altool_password" \
                     --file JustMonika.saver.zip
        ```
    - Wait for an email with notification
    - Staple the notarization ticket to the bundle
      - `xcrun stapler staple JustMonika.saver`
      - `spctl -vvv --assess --type install JustMonika.saver`
        - `JustMonika.saver: accepted`
        - `source=Notarized Developer ID`
        - `origin=Developer ID Application: ...`
    - In case of issues, use these:
      - [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution)
      - [Resolving Common Notarization Issues](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution/resolving_common_notarization_issues)
      - [Customizing the Notarization Workflow](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)

4. Prepare distribution archive

    - Pack the stapled bundle into a ZIP archive and sign it
    - `zip --symlink -r JustMonika.saver.zip JustMonika.saver`
    - `gpg --armor --detach-sig --output JustMonika.saver.zip.asc JustMonika.saver.zip`
    - `gpg --verify JustMonika.saver.zip.asc JustMonika.saver.zip`

5. Tag the release

    - Update download version in README.md
    - `git add JustMonika.xcodeproj README.md`
    - `git commit -m "JustMonika.saver v2.0"`
    - `GPG_TTY=$(tty) git tag -s v2.0`
    - `git push origin v2.0`

6. Draft GitHub release

    - Use the previously created tag
    - Make sure it’s marked **Verified**
    - Attach release binaries
      - `JustMonika.saver.zip`
      - `JustMonika.saver.zip.asc`
    - Download the release, try using it

7. Publish release on GitHub

8. Prepare for next release

    - Update “marketing version” to next number (e.g., 2.1), add `-dev` suffix
    - Increment machine-readable version
    - Do this for both **JustMonika** and **JustMonikaGL** targets
    - `git commit -m "Start working on v2.1"`
    - `git push`
