package_options = ''

platform_family = node['platform_family']
platform_version = node['platform_version'].to_i

case platform_family
when 'debian'
  package_options = '--force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"'

  include_recipe 'apt'
  package 'apt-transport-https'

  apt_repository 'grafana' do
    repo = node['grafana']['use_unstable_repo'] ? 'grafana/testing' : 'grafana/stable'
    uri "#{node['grafana']['repo_url']}/#{repo}/debian"
    distribution ''
    components %w(wheezy main)
    key "#{node['grafana']['repo_url']}/gpg.key"
    action :add
  end
else
  rhel_version_equivalent =
    case platform_family
    when 'rhel'
      if platform?('amazon') || platform_version >= 7
        6
      else
        platform_version
      end
    when 'fedora'
      case platform_version
      when 6..11 then 5
      when 12..18 then 6
      else
        fail "Cannot map fedora version #{platform_version} to a RHEL version. aborting"
      end
    else
      fail "Unsupported Linux platform family #{platform_family}"
  end

  repo = yum_repository 'grafana' do
    description 'grafana'
    repo = node['grafana']['use_unstable_repo'] ? 'grafana/testing' : 'grafana/stable'
    url "#{node['grafana']['repo_url']}/#{repo}/el/#{rhel_version_equivalent}/$basearch/"
    action :add
  end
  repo.gpgcheck(false) if repo.respond_to?(:gpgcheck)
end

case platform_family
when 'debian'
  package 'grafana' do
    version node['grafana']['version']
    options package_options
    action :upgrade
  end
else
  yum_package 'grafana' do
    version node['grafana']['version']
    options package_options
    allow_downgrade true
    action :upgrade
  end
end
