FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS build
WORKDIR /app
EXPOSE 80
EXPOSE 443

WORKDIR /src
COPY ["Transfers.API.csproj", "./"]
RUN dotnet restore "./Transfers.API.csproj"
COPY . . 
RUN dotnet publish -c Release -o out

FROM build AS publish

RUN apk add curl

FROM mcr.microsoft.com/dotnet/aspnet:5.0-alpine-amd64 AS runtime
RUN apk add curl
WORKDIR /app
COPY --from=publish /src/out ./

ENTRYPOINT ["dotnet", "Transfers.API.dll"]
