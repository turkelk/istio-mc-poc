using System.Threading.Tasks;
using Quantic.Core;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using Retail.API.Model;

namespace Retail.API.Commands
{
    public class DoTransferHandler : ICommandHandler<DoTransfer>
    {
        private readonly HttpClient httpClient;
        private readonly Config config;

        public DoTransferHandler(HttpClient httpClient, Config config)
        {
            this.httpClient = httpClient;
            this.config = config;
        }

        public async Task<CommandResult> Handle(DoTransfer command, RequestContext context)
        {
            var request = new HttpRequestMessage(HttpMethod.Post, $"{config.TransfersApiUrl}");
            request.Content = new StringContent(JsonSerializer.Serialize(command), Encoding.UTF8, "application/json");

            request.Headers.Add("Accept", "application / json");
            request.Headers.Add("quantic-trace-id", context.TraceId);

            var response = await httpClient.SendAsync(request);

            // if (!response.IsSuccessStatusCode)
            //     return QueryResult<Account>.WithError(Msg.GetAccountError, $"status code is {response.IsSuccessStatusCode}");

            return CommandResult.Success;
        }
    }
    public class DoTransfer : ICommand
    {
        public DoTransfer(string sender, string receiver, double amount, string currency)
        {
            Sender = sender;
            Receiver = receiver;
            Amount = amount;
            Currency = currency;
        }

        public string Sender { get; }
        public string Receiver { get; }
        public double Amount { get; }
        public string Currency { get; }        
    }
}
