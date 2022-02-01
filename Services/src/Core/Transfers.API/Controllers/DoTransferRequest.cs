using System.Threading.Tasks;
using Quantic.Core;
using Transfers.API.Model;
using Transfers.API.Query;

namespace Transfers.API.Controllers
{
    public class DoTransferRequest
    {
        public string Sender { get; set; }
        public string Receiver { get; set; }
        public double Amount { get; set; }
        public string Currency { get; set; }        
    }
}
