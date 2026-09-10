// Copyright (c) 2002-present, OpenMS Inc. -- EKU Tuebingen, ETH Zurich, and FU Berlin
// SPDX-License-Identifier: BSD-3-Clause
// --------------------------------------------------------------------------
// $Maintainer: $
// $Authors: OpenMS contributors, with AI-assisted test implementation $
// --------------------------------------------------------------------------

#include <OpenMS/FORMAT/MascotRemoteQuery.h>

#include <cstdlib>
#include <iostream>
#include <string>

int main(int argc, char** argv)
{
  if (argc != 3)
  {
    std::cerr << "Expected local server port and response scenario\n";
    return EXIT_FAILURE;
  }
  const std::string scenario = argv[2];
  OpenMS::MascotRemoteQuery query;
  OpenMS::Param parameters = query.getParameters();
  parameters.setValue("hostname", "127.0.0.1");
  parameters.setValue("host_port", std::stoi(argv[1]));
  parameters.setValue("server_path", "mascot");
  parameters.setValue("timeout", 5);
  parameters.setValue("login", "false");
  parameters.setValue("use_ssl", "false");
  query.setParameters(parameters);
  query.setQuerySpectra("BEGIN IONS\nTITLE=local transport regression\n500.0 100.0\nEND IONS\n");
  query.setExportDecoys(true);
  query.run();

  if (scenario == "success")
  {
    if (query.hasError() || query.getSearchIdentifier() != "000123" ||
        query.getMascotXMLResponse() != "<mascot_search_results><target>local</target></mascot_search_results>" ||
        query.getMascotXMLDecoyResponse() != "<mascot_search_results><decoy>local</decoy></mascot_search_results>")
    {
      std::cerr << "Upload/export did not preserve the search ID and target/decoy responses: "
                << query.getErrorMessage() << '\n';
      return EXIT_FAILURE;
    }
  }
  else if (scenario == "post_error" || scenario == "get_error")
  {
    const std::string expected_identifier = scenario == "post_error" ? "" : "000123";
    if (!query.hasError() || query.getErrorMessage().find("HTTP error 503") == std::string::npos ||
        !query.getMascotXMLResponse().empty() || !query.getMascotXMLDecoyResponse().empty() ||
        query.getSearchIdentifier() != expected_identifier)
    {
      std::cerr << "HTTP failure did not preserve the expected error/result state: "
                << query.getErrorMessage() << '\n';
      return EXIT_FAILURE;
    }
  }
  else
  {
    std::cerr << "Unknown response scenario\n";
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
