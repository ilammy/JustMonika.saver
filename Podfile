platform :macos, 10.12

inhibit_all_warnings!

target 'JustMonika' do
  pod 'Sparkle'

  target 'JustMonikaGL' do
    pod 'libpng', '~> 1.6'
  end
end

target 'JustMonika (no Sparkle)' do
  target 'JustMonikaGL' do
    pod 'libpng', '~> 1.6'
  end
end
