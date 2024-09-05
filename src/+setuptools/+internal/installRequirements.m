function installRequirements(mode, options)

    arguments (Repeating)
        mode string {mustBeMember(mode, ["force", "f", "update", "u"])}
    end
    
    arguments
        % Tentative, not implemented yet!
        options.UseDefaultInstallationLocation (1,1) logical = true
        options.UpdateSearchPath (1,1) logical = true
        options.InstallationLocation (1,1) string = setuptools.internal.getDefaultAddonFolder()
    end

    doUpdate = any(strcmp(mode, {'update'})) || any( strcmp(mode, {'u'}) );
    %Todo.
    
    reqs = setuptools.internal.getRequirements();
    
    installationLocation = options.InstallationLocation;
    if ~isfolder(installationLocation); mkdir(installationLocation); end

    for i = 1:numel(reqs)
        switch reqs(i).Type
            case 'GitHub'
                [repoUrl, branchName] = parseGitHubUrl(reqs(i).URI);
                setuptools.internal.installGithubRepository( repoUrl, branchName )
            case 'FileExchange'
                [packageUuid, version] = getFEXPackageSpecification( reqs(i).URI );
                setuptools.internal.installFexPackage(packageUuid, installationLocation, 'Version', version);

            case 'Unknown'
                continue
        end        
    end
end

function [packageUuid, version] = getFEXPackageSpecification(uri)
% getFEXPackageSpecification - Get UUID and version for package
%
%   NB: This function relies on an undocumented api, and might break in the
%   future.

    version = "latest"; % Initialize default value

    FEX_API_URL = "https://addons.mathworks.com/registry/v1/";
    
    splitUri = strsplit(uri, '/');

    packageNumber = regexp(splitUri{2}, '\d*(?=-)', 'match', 'once');
    try
        packageInfo = webread(FEX_API_URL + num2str(packageNumber));
        packageUuid = packageInfo.uuid;
    catch ME
        switch ME.identifier
            case 'MATLAB:webservices:HTTP404StatusCodeError'
                error('FEX package with identifier "%s" was not found', splitUri{2})
            otherwise
                rethrow(ME)
        end
    end

    if numel(splitUri) == 3
        version = string( splitUri{3} );
        assert( any(strcmp(packageInfo.versions, version) ), ...
            'Specified version "%s" is not supported for FEX package "%s"', ...
            version, splitUri{2});
    end
end

function [repoUrl, branchName] = parseGitHubUrl(repoUrl)
% parseGitHubUrl - Extract branchname if present
    branchName = string(missing);
    if contains(repoUrl, '@')
        splitUrl = strsplit(repoUrl, '@');
        repoUrl = splitUrl{1};
        branchName = splitUrl{2};
    end
end
